/*
 * Copyright (c) 2018, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package no.nordicsemi.android.mesh.transport;

import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import androidx.annotation.NonNull;
import no.nordicsemi.android.mesh.Features;
import no.nordicsemi.android.mesh.NetworkKey;
import no.nordicsemi.android.mesh.opcodes.ConfigMessageOpCodes;
import no.nordicsemi.android.mesh.utils.MeshAddress;
import no.nordicsemi.android.mesh.utils.MeshParserUtils;

/**
 * To be used as a wrapper class to create the ConfigHeartbeatPublicationSet message.
 */
@SuppressWarnings("unused")
public class ConfigHeartbeatPublicationSet extends ConfigMessage {

    private static final String TAG = ConfigHeartbeatPublicationSet.class.getSimpleName();
    private static final int OP_CODE = ConfigMessageOpCodes.CONFIG_HEARTBEAT_PUBLICATION_SET;
    private final int dstAddress;
    private final int countLog;
    private final int periodLog;
    private final int ttl;
    private final Features features;
    private final NetworkKey networkKey;

    /**
     * Constructs ConfigHeartbeatPublicationSet message.
     *
     * @param dstAddress Destination address identifies the Heartbeat Publication
     *                   destination where the address can only be an unassigned address,
     *                   unicast address or a group address. All other values are prohibited.
     * @param countLog   Number of Heartbeat messages to be sent.
     * @param periodLog  Period for sending Heartbeat messages.
     * @param ttl        TTL to be used when sending Heartbeat messages.
     * @param features   Bit field indicating features that trigger Heartbeat messages when changed.
     * @param networkKey Network key.
     * @throws IllegalArgumentException if any illegal arguments are passed
     */
    public ConfigHeartbeatPublicationSet(final int dstAddress,
                                         final int countLog,
                                         final int periodLog,
                                         final int ttl,
                                         @NonNull final Features features,
                                         final NetworkKey networkKey) throws IllegalArgumentException {
        if (!MeshAddress.isValidHeartbeatPublicationDestination(dstAddress))
            throw new IllegalArgumentException("Destination address must be an unassigned address, " +
                    "a unicast address, or a group address, all other values are Prohibited!");
        this.dstAddress = dstAddress;
        if (!MeshParserUtils.isValidHeartbeatCountLog(countLog))
            throw new IllegalArgumentException("Count log must not be within the prohibited range of 0x12 to 0xFE!");
        this.countLog = countLog;
        if (!MeshParserUtils.isValidHeartbeatPeriodLog(periodLog))
            throw new IllegalArgumentException("Period log must be within the range of 0x00 to 0x11!");
        this.periodLog = periodLog;
        if (!MeshParserUtils.isValidHeartbeatPublicationTtl(ttl))
            throw new IllegalArgumentException("Heartbeat ttl must be within the range of 0x00 to 0x7F!");
        this.ttl = ttl;
        this.features = features;
        this.networkKey = networkKey;
        assembleMessageParameters();
    }

    @Override
    public int getOpCode() {
        return OP_CODE;
    }

    @Override
    void assembleMessageParameters() {
        Log.d(TAG, "Destination address: " + Integer.toHexString(dstAddress));
        Log.d(TAG, "Count Log: " + Integer.toHexString(countLog));
        Log.d(TAG, "Period Log: " + Integer.toHexString(periodLog));
        Log.d(TAG, "TTL: " + Integer.toHexString(dstAddress));
        Log.d(TAG, "Features: " + features.toString());
        Log.d(TAG, "Net key index: " + Integer.toHexString(networkKey.getKeyIndex()));
        final byte[] netKeyIndex = MeshParserUtils.addKeyIndexPadding(networkKey.getKeyIndex());
        final ByteBuffer paramsBuffer = ByteBuffer.allocate(9).order(ByteOrder.LITTLE_ENDIAN);
        paramsBuffer.putShort((short) dstAddress);
        paramsBuffer.put((byte) countLog);
        paramsBuffer.put((byte) periodLog);
        paramsBuffer.put((byte) ttl);
        paramsBuffer.put(features.toByteArray());
        paramsBuffer.put(netKeyIndex[1]);
        paramsBuffer.put((byte) ((netKeyIndex[0] & 0xFF) & 0x0F));
        mParameters = paramsBuffer.array();
    }
}
