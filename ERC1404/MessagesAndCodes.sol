// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library MessagesAndCodes {
    error EmptyMessageError();
    error CodeReservedError();
    error CodeUnassignedError();

    struct Data {
        mapping(uint8 => string) messages;
        uint8[] codes;
    }

    function messageIsEmpty(string memory _message)
        internal
        pure
        returns (bool)
    {
        return bytes(_message).length == 0;
    }

    function messageExists(Data storage self, uint8 _code)
        internal
        view
        returns (bool)
    {
        return bytes(self.messages[_code]).length > 0;
    }

    function addMessage(
        Data storage self,
        uint8 _code,
        string memory _message
    ) public {
        if (messageIsEmpty(_message)) revert EmptyMessageError();
        if (messageExists(self, _code)) revert CodeReservedError();

        self.messages[_code] = _message;
        self.codes.push(_code);
    }

    function autoAddMessage(Data storage self, string memory _message)
        public
        returns (uint8)
    {
        if (messageIsEmpty(_message)) revert EmptyMessageError();

        uint8 code = 0;
        while (messageExists(self, code)) {
            code++;
        }

        addMessage(self, code, _message);
        return code;
    }

    function removeMessage(Data storage self, uint8 _code) public {
        if (!messageExists(self, _code)) revert CodeUnassignedError();

        uint8 indexOfCode = 0;
        while (self.codes[indexOfCode] != _code) {
            indexOfCode++;
        }

        for (uint8 i = indexOfCode; i < self.codes.length - 1; i++) {
            self.codes[i] = self.codes[i + 1];
        }
        self.codes.pop();

        delete self.messages[_code];
    }

    function updateMessage(
        Data storage self,
        uint8 _code,
        string memory _message
    ) public {
        if (messageIsEmpty(_message)) revert EmptyMessageError();
        if (!messageExists(self, _code)) revert CodeUnassignedError();

        self.messages[_code] = _message;
    }
}
