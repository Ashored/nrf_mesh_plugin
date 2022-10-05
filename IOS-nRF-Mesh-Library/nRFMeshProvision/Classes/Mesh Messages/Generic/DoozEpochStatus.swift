//
/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public struct DoozEpochStatus: GenericMessage {
    public static var opCode: UInt32 = 0x8222

    public var parameters: Data? {
        var data = Data() + tid
        print("📣mPacked: \(mPacked) (\(String(mPacked, radix: 2)))")
        print("📣mEpoch: \(mEpoch)")
        print("📣mCorrelation: \(mCorrelation)")
        data += mPacked
        data += mEpoch
        data += mCorrelation
        if let extra = mExtra {
            print("📣mExtra: \(String(describing: extra))")
            data += UInt16(extra)
        }
        return data
    }

    public let mPacked: UInt16
    public let mEpoch: UInt32
    public let mCorrelation: UInt32
    public let mExtra: UInt16?
    public let tid: UInt8

    /// Creates the DoozEpochStatus message.
    ///
    /// - parameters:
    ///   - packed               A bitmap containing the time zone, the command and the io of this message
    ///   - epoch                The current Epoch
    ///   - correlation          Correlation to link request / response
    ///   - extra                RFU
    ///   - tid                  Transaction id
    public init(packed: UInt16, epoch: UInt32, correlation: UInt32, extra: UInt16?, tid: UInt8) {
        self.mPacked = packed
        self.mEpoch = epoch
        self.mCorrelation = correlation
        self.mExtra = extra
        self.tid = tid
    }

    public init?(parameters: Data) {
        tid = parameters[0]
        mPacked = parameters.read(fromOffset: 1)
        print("📣mPacked: \(mPacked) (\(String(mPacked, radix: 2)))")
        mEpoch = parameters.read(fromOffset: 3)
        print("📣mEpoch: \(mEpoch)")
        mCorrelation = parameters.read(fromOffset: 7)
        print("📣mCorrelation: \(mCorrelation)")
        if parameters.count == 5 {
            mExtra = parameters.read(fromOffset: 11)
            print("📣mExtra: \(String(describing: mExtra))")
        } else {
            mExtra = nil
        }
    }
}
