/*
 * Copyright © 2017-2023 WireGuard LLC. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package org.amnezia.awg.preference

import android.content.Context
import android.util.AttributeSet
import androidx.preference.Preference
import org.amnezia.awg.Application
import org.amnezia.awg.R
import org.amnezia.awg.backend.Tunnel
import org.amnezia.awg.model.ObservableTunnel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Заменяет Quick Settings Tile (недоступен на Android < 7.0, а по решению скоупа — исключён совсем)
 * на элемент настроек, показывающий текущее состояние туннеля. Управление туннелем остаётся
 * только в основном UI приложения; здесь — пассивный индикатор статуса.
 */
class TunnelStatusPreference(context: Context, attrs: AttributeSet?) : Preference(context, attrs) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var subscribedTunnel: ObservableTunnel? = null

    init {
        isSelectable = false
        updateSummary(null)
        scope.launch {
            val tunnels = Application.getTunnelManager().getTunnels()
            val lastUsed = Application.getTunnelManager().lastUsedTunnel
                ?: tunnels.firstOrNull { it.state == Tunnel.State.UP }
                ?: tunnels.firstOrNull()
            if (lastUsed !== subscribedTunnel) {
                subscribedTunnel?.removeOnPropertyChangedCallback(stateCallback)
                subscribedTunnel = lastUsed
                lastUsed?.addOnPropertyChangedCallback(stateCallback)
            }
            updateSummary(lastUsed)
        }
    }

    private val stateCallback = object : androidx.databinding.Observable.OnPropertyChangedCallback() {
        override fun onPropertyChanged(sender: androidx.databinding.Observable?, propertyId: Int) {
            updateSummary(subscribedTunnel)
        }
    }

    private fun updateSummary(tunnel: ObservableTunnel?) {
        summary = when (tunnel?.state) {
            Tunnel.State.UP -> context.getString(R.string.tunnel_status_up)
            Tunnel.State.DOWN -> context.getString(R.string.tunnel_status_down)
            else -> context.getString(R.string.tunnel_status_none)
        }
    }

    override fun onDetached() {
        subscribedTunnel?.removeOnPropertyChangedCallback(stateCallback)
        super.onDetached()
    }
}
