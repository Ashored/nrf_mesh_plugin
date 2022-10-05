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

public struct MagicLevelGetStatus: GenericMessage {
    public static var opCode: UInt32 = 0x8226
    
    public var parameters: Data? {
        return Data() + mIO + mIndex + mValue + mCorrelation + tid
    }
    
    public let mIO: UInt8
    
    public let mIndex: UInt16
    
    public let mValue: UInt32
    
    public let mCorrelation: UInt32
    
    public let tid: UInt8
    
    /// Creates the Magic Level Get Status message.
    ///
    /// - parameters:
    ///   - io: The target io of the magic level server model.
    ///   - index: The target LUT index of the magic level server model.
    ///   - value: The value in the LUT.
    ///   - correlation: The correlation value.
    ///   - tid: The transaction id
    public init(io: UInt8, index: UInt16, value: UInt32, correlation: UInt32, tid: UInt8) {
        self.mIO = io
        self.mIndex = index
        self.mValue = value
        self.mCorrelation = correlation
        self.tid = tid
    }
    
    public init?(parameters: Data) {
        mIO = parameters[0]
        mIndex = parameters.read(fromOffset: 1)
        mValue = parameters.read(fromOffset: 3)
        mCorrelation = parameters.read(fromOffset: 7)
        tid = parameters[11]
    }
}
