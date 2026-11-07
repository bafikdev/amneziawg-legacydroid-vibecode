/*
 * Copyright © 2017-2023 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package org.amnezia.awg.util

import android.content.RestrictionsManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.content.getSystemService
import org.amnezia.awg.Application

object AdminKnobs {
    val disableConfigExport: Boolean
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
            AdminKnobsLollipop.disableConfigExport
        else
            false

    /**
     * RestrictionsManager itself and getApplicationRestrictions() are API 21+. Keeping them in a
     * nested object avoids touching the class on KitKat.
     */
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private object AdminKnobsLollipop {
        private val restrictions: RestrictionsManager? = Application.get().getSystemService()
        val disableConfigExport: Boolean
            get() = restrictions?.applicationRestrictions?.getBoolean("disable_config_export", false)
                ?: false
    }
}
