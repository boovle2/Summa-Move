package nl.summacollege.summamove.summamove_mobile

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.NutritionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Duration
import java.time.Instant
import java.util.TimeZone
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissions = emptySet<String>()

    private val permissionLauncher =
        registerForActivityResult(PermissionController.createRequestPermissionResultContract()) { granted ->
            pendingPermissionResult?.success(granted.containsAll(pendingPermissions))
            pendingPermissionResult = null
            pendingPermissions = emptySet()
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "summamove/health")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(isHealthConnectAvailable(call.source))
                    "requestPermissions" -> requestPermissions(call, result)
                    "readChanges" -> readChanges(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private val MethodCall.source: String
        get() = argument<String>("source") ?: ""

    private fun isHealthConnectAvailable(source: String): Boolean {
        return source == "health_connect" &&
            HealthConnectClient.getSdkStatus(this) == HealthConnectClient.SDK_AVAILABLE
    }

    private fun requestPermissions(call: MethodCall, result: MethodChannel.Result) {
        if (!isHealthConnectAvailable(call.source)) {
            result.success(false)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_request_active", "Er loopt al een Health Connect permissieverzoek.", null)
            return
        }

        val permissions = permissionsFor(call.argument<List<String>>("metrics") ?: emptyList())
        scope.launch {
            try {
                val granted = healthClient().permissionController.getGrantedPermissions()
                if (granted.containsAll(permissions)) {
                    result.success(true)
                    return@launch
                }
                pendingPermissionResult = result
                pendingPermissions = permissions
                permissionLauncher.launch(permissions)
            } catch (error: Throwable) {
                result.error("health_permissions_failed", error.message, null)
            }
        }
    }

    private fun readChanges(call: MethodCall, result: MethodChannel.Result) {
        if (!isHealthConnectAvailable(call.source)) {
            result.error("health_connect_unavailable", "Health Connect is niet beschikbaar op dit toestel.", null)
            return
        }

        scope.launch {
            try {
                val rawFrom = Instant.parse(call.argument<String>("from"))
                val to = Instant.parse(call.argument<String>("to"))
                val from = maxInstant(parseCursor(call.argument<String>("cursor")) ?: rawFrom, rawFrom)
                val payload = withContext(Dispatchers.IO) { readHealthConnect(from, to) }
                result.success(payload)
            } catch (error: Throwable) {
                result.error("health_read_failed", error.message, null)
            }
        }
    }

    private suspend fun readHealthConnect(from: Instant, to: Instant): Map<String, Any?> {
        val records = mutableListOf<Map<String, Any?>>()
        val workouts = mutableListOf<Map<String, Any?>>()
        val client = healthClient()
        val range = TimeRangeFilter.between(from, to)
        val timezone = TimeZone.getDefault().id

        fun hasRoom(): Boolean = records.size + workouts.size < 500

        readSteps(client, range, timezone, records, ::hasRoom)
        readHeartRate(client, range, timezone, records, ::hasRoom)
        readActiveCalories(client, range, timezone, records, ::hasRoom)
        readNutrition(client, range, timezone, records, ::hasRoom)
        readHydration(client, range, timezone, records, ::hasRoom)
        readExercises(client, range, timezone, workouts, ::hasRoom)

        return mapOf(
            "cursor" to to.toString(),
            "records" to records,
            "workouts" to workouts,
        )
    }

    private suspend fun readSteps(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                if (!hasRoom()) return
                output.add(
                    scalarRecord(
                        record.metadata.id,
                        "steps",
                        record.count,
                        "count",
                        timezone,
                        measuredFrom = record.startTime,
                        measuredTo = record.endTime,
                        sourceApp = record.metadata.dataOrigin.packageName,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private suspend fun readHeartRate(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                for (sample in record.samples) {
                    if (!hasRoom()) return
                    output.add(
                        scalarRecord(
                            "${record.metadata.id}:${sample.time}",
                            "heart_rate",
                            sample.beatsPerMinute,
                            "bpm",
                            timezone,
                            measuredAt = sample.time,
                            sourceApp = record.metadata.dataOrigin.packageName,
                        ),
                    )
                }
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private suspend fun readActiveCalories(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = ActiveCaloriesBurnedRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                if (!hasRoom()) return
                output.add(
                    scalarRecord(
                        record.metadata.id,
                        "active_energy_burned",
                        record.energy.inKilocalories,
                        "kcal",
                        timezone,
                        measuredFrom = record.startTime,
                        measuredTo = record.endTime,
                        sourceApp = record.metadata.dataOrigin.packageName,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private suspend fun readNutrition(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = NutritionRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                val energy = record.energy ?: continue
                if (!hasRoom()) return
                output.add(
                    scalarRecord(
                        record.metadata.id,
                        "dietary_energy_consumed",
                        energy.inKilocalories,
                        "kcal",
                        timezone,
                        measuredFrom = record.startTime,
                        measuredTo = record.endTime,
                        sourceApp = record.metadata.dataOrigin.packageName,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private suspend fun readHydration(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HydrationRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                if (!hasRoom()) return
                output.add(
                    scalarRecord(
                        record.metadata.id,
                        "water_intake",
                        record.volume.inMilliliters,
                        "ml",
                        timezone,
                        measuredFrom = record.startTime,
                        measuredTo = record.endTime,
                        sourceApp = record.metadata.dataOrigin.packageName,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private suspend fun readExercises(
        client: HealthConnectClient,
        range: TimeRangeFilter,
        timezone: String,
        output: MutableList<Map<String, Any?>>,
        hasRoom: () -> Boolean,
    ) {
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = range,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                if (!hasRoom()) return
                output.add(
                    mapOf(
                        "external_id" to externalId(record.metadata.id, "workout:${record.startTime}:${record.endTime}"),
                        "activity_type" to activityType(record.exerciseType),
                        "started_at" to record.startTime.toString(),
                        "ended_at" to record.endTime.toString(),
                        "active_duration_seconds" to Duration.between(record.startTime, record.endTime).seconds.toInt(),
                        "timezone" to timezone,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null && hasRoom())
    }

    private fun scalarRecord(
        id: String,
        metricType: String,
        value: Number,
        unit: String,
        timezone: String,
        measuredAt: Instant? = null,
        measuredFrom: Instant? = null,
        measuredTo: Instant? = null,
        sourceApp: String? = null,
    ): Map<String, Any?> {
        return mapOf(
            "external_id" to externalId(id, "$metricType:${measuredAt ?: measuredFrom}:${measuredTo ?: ""}"),
            "metric_type" to metricType,
            "value" to value,
            "unit" to unit,
            "timezone" to timezone,
            "measured_at" to measuredAt?.toString(),
            "measured_from" to measuredFrom?.toString(),
            "measured_to" to measuredTo?.toString(),
            "source_app" to sourceApp,
        ).filterValues { it != null }
    }

    private fun permissionsFor(metrics: List<String>): Set<String> {
        val requested = if (metrics.isEmpty()) {
            setOf(
                "steps",
                "heart_rate",
                "active_energy_burned",
                "dietary_energy_consumed",
                "water_intake",
                "workout_session",
            )
        } else {
            metrics.toSet()
        }

        return buildSet {
            if ("steps" in requested) add(HealthPermission.getReadPermission(StepsRecord::class))
            if ("heart_rate" in requested) add(HealthPermission.getReadPermission(HeartRateRecord::class))
            if ("active_energy_burned" in requested) add(HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class))
            if ("dietary_energy_consumed" in requested) add(HealthPermission.getReadPermission(NutritionRecord::class))
            if ("water_intake" in requested) add(HealthPermission.getReadPermission(HydrationRecord::class))
            if ("workout_session" in requested) add(HealthPermission.getReadPermission(ExerciseSessionRecord::class))
        }
    }

    private fun healthClient(): HealthConnectClient = HealthConnectClient.getOrCreate(this)

    private fun parseCursor(cursor: String?): Instant? {
        if (cursor.isNullOrBlank()) return null
        return runCatching { Instant.parse(cursor) }.getOrNull()
    }

    private fun maxInstant(left: Instant, right: Instant): Instant = if (left.isAfter(right)) left else right

    private fun externalId(id: String, fallback: String): String = id.ifBlank { fallback }

    private fun activityType(type: Int): String {
        return when (type) {
            ExerciseSessionRecord.EXERCISE_TYPE_BIKING -> "cycling"
            ExerciseSessionRecord.EXERCISE_TYPE_RUNNING -> "running"
            ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> "walking"
            ExerciseSessionRecord.EXERCISE_TYPE_YOGA -> "yoga"
            else -> "workout"
        }
    }
}
