using System;
using System.Data;
using System.Data.SqlClient;
using System.Xml;

namespace GisGmp
{
    public class RequestManager
    {
        #region CONST

        private const string NEXT_REQUEST_SQL_SP = "gisgmp_sp_GetNextRequest";
        private const string INSERT_RESPONSE_SQL_SP = "gisgmp_sp_InserttResponse";
        #endregion // CONST

        #region Constructor

        public RequestManager() { }
        #endregion // Constructor

        #region Methods

        public void SendNextRequest()
        {
            Request nextRequest = this.GetNextRequest();

            if (nextRequest == null)
            {
                return;
            }

            Response response = nextRequest.Send();

            if (response == null)
            {
                throw new HaveNotResponseException();
            }

            this.AddResponse(response);
        }

        private void AddResponse(Response response)
        {
            var connection = new SqlConnection(Config.RootCfgObject.Read().ConnectionStrings);
            SqlCommand command = new SqlCommand(INSERT_RESPONSE_SQL_SP, connection);
            command.CommandType = System.Data.CommandType.StoredProcedure;
            command.Parameters.Add("Xml", System.Data.SqlDbType.Xml);


            if (response.Xml.FirstChild.NodeType == XmlNodeType.XmlDeclaration)
            {
                response.Xml.RemoveChild(response.Xml.FirstChild);
            }

            command.Parameters["Xml"].Value = response.Xml.InnerXml;

            command.Connection.Open();
            command.ExecuteNonQuery();
            command.Connection.Close();
        }

        private Request GetNextRequest()
        {
            var connection = new SqlConnection(Config.RootCfgObject.Read().ConnectionStrings);
            SqlCommand command = new SqlCommand(NEXT_REQUEST_SQL_SP, connection);
            command.CommandType = System.Data.CommandType.StoredProcedure;

            command.Connection.Open();
            SqlDataReader reader = command.ExecuteReader();

            if (!reader.HasRows)
            {
                command.Connection.Close();
                return null;
            }

            DataTable table = new DataTable();
            table.Load(reader);

            command.Connection.Close();

            if (table.Rows.Count != 1)
            {
                throw new Exception();
            }

            var requestXml = new XmlDocument();
            requestXml.LoadXml((string)table.Rows[0]["Xml"]);
            Request nextRequest = new Request(requestXml);

            return nextRequest;
        }
        #endregion // Methods
    }
}