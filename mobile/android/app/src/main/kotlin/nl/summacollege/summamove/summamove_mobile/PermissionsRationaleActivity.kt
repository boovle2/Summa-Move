package nl.summacollege.summamove.summamove_mobile

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView

class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(
            TextView(this).apply {
                text = "SummaMove leest Health Connect-data alleen om je stappen, hartslag, actieve calorieen, water, voeding en workouts te synchroniseren met je eigen challenges. De app schrijft geen data terug naar Health Connect."
                textSize = 18f
                gravity = Gravity.CENTER
                setPadding(48, 48, 48, 48)
            },
        )
    }
}
