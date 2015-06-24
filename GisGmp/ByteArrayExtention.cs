namespace GisGmp
{
    static class ByteArrayExtention
    {
        public static bool TrueEquals(this byte[] arr, byte[] obj)
        {
            if (arr == null || obj == null) { return false; }

            if (arr.Length != obj.Length) { return false; }

            for (int i = 0; i < arr.Length; i++)
            {
                if (arr[i] != obj[i]) { return false; }
            }

            return true;
        }
    }
}
