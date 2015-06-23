using System;

namespace GisGmp.Cryptography
{
    class SignElementException : Exception
    {
        public SignElementException() : base() { }

        public SignElementException(string message) : base(message) { }
    }
}
