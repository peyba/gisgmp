﻿using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;

namespace GisGmp.Config
{
    [DataContract]
    public class RootCfgObject
    {
        public const string CFG_FILE_NAME = @"GisGmp.config.json";

        [DataMember(Name = "send")]
        public SendCfgObject Send { get; set; }

        [DataMember(Name = "certificate")]
        public string Certificate { get; set; }

        [DataMember(Name = "connectionstring")]
        public string ConnectionStrings { get; set; }

        protected RootCfgObject() { }

        private static RootCfgObject Read(string cfgFileName)
        {
            string strAppDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string cfgFilePath = Path.Combine(strAppDir, cfgFileName);

            RootCfgObject cfgObject;
            using (var cfgFileStream = new FileStream(cfgFilePath, FileMode.Open))
            {
                 /* 
                 * проблема: метод ReadObject класса DataContractJsonSerializer падает по ошибке 
                 * SerializationException при попытке распарсить json-документ 
                 * содержащий Byte Order Mark (BOM)
                 * решение: перематываем на первыйсущественный байт
                 */
                cfgFileStream.RewindBOM();

                var cfgSerializer = new DataContractJsonSerializer(typeof(RootCfgObject));
                cfgObject = (RootCfgObject)cfgSerializer.ReadObject(cfgFileStream);

                cfgFileStream.Close();
            }

            return cfgObject;
        }

        public static RootCfgObject Read()
        {
            return RootCfgObject.Read(CFG_FILE_NAME);
        }
    }
}
