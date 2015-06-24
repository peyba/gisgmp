using System.IO;

namespace GisGmp
{
    static class FileStreamExtention
    {
        public static FileStream RewindBOM(this FileStream stream)
        {
            var bolBytesSequenceArray = new byte[][]
            {
                new byte[] { 239, 187, 191 }, /* UTF-8 */
                new byte[] { 254, 255 }, /* UTF-16 (BE) */
                new byte[] { 255, 254 }, /* UTF-16 (LE) */
                new byte[] { 0, 0, 254, 255 }, /* UTF-32 (BE) */
                new byte[] { 255, 254, 0, 0 } /* UTF-32 (LE) */
            };

            foreach (var bom in bolBytesSequenceArray)
            {
                var streamFirstBytes = new byte[bom.Length];
                stream.Read(streamFirstBytes, 0, bom.Length);
                if (streamFirstBytes.TrueEquals(bom))
                {
                    return stream;
                }

                stream.Position = 0;
            }

            return stream;
        }
    }
}
