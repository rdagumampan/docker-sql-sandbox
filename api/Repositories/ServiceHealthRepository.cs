using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace aspnet_core_dotnet_core
{
       public class ServiceHealthRepository : IServiceHealthRepository
    {
        string connectionString = "";

        public List<ServiceHealthDbModel> All()
        {
            var results = new List<ServiceHealthDbModel>();

            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandType = System.Data.CommandType.Text;
                command.CommandText = "SELECT * FROM [dbo].[ServiceHealth];";

                var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    var status = new ServiceHealthDbModel
                    {
                        ServiceId = reader.GetString(0),
                        ServiceName = reader.GetString(1),
                        Description = reader.GetString(2),
                        Location = reader.GetString(3),
                        LastPing = reader.GetDateTime(4),
                        LastStatus = reader.GetString(5),
                    };
                    results.Add(status);
                }

                return results;
            }
        }

        public int Create(ServiceHealthDbModel status)
        {
            using(var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandType = System.Data.CommandType.Text;
                command.CommandText = @"
                INSERT INTO [dbo].[ServiceHealth]
                       ([ServiceId]
                       ,[ServiceName]
                       ,[Description]
                       ,[Location]
                       ,[LastPing]
                       ,[LastStatus]
                ) VALUES (
                        @ServiceId
                       ,@ServiceName
                       ,@Description
                       ,@Location
                       ,@LastPing
                       ,@LastStatus
	                );";

                command.Parameters.AddWithValue("@ServiceId", status.ServiceId);
                command.Parameters.AddWithValue("@ServiceName", status.ServiceName);
                command.Parameters.AddWithValue("@Description", status.Description);
                command.Parameters.AddWithValue("@Location", status.Location);
                command.Parameters.AddWithValue("@LastPing", status.LastPing);
                command.Parameters.AddWithValue("@LastStatus", status.LastStatus);

                var affectedRows = command.ExecuteNonQuery();
                return affectedRows;
            }
        }

        public int Update(ServiceHealthDbModel status)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandType = System.Data.CommandType.Text;
                command.CommandText = @"
                UPDATE [dbo].[ServiceHealth]
                SET
                        [Location] = @Location
                       ,[LastPing] = @LastPing
                       ,[LastStatus] = @LastStatus
                WHERE
                    [ServiceId] = @ServiceId;
                ";

                command.Parameters.AddWithValue("@ServiceId", status.ServiceId);
                command.Parameters.AddWithValue("@Location", status.Location);
                command.Parameters.AddWithValue("@LastPing", status.LastPing);
                command.Parameters.AddWithValue("@LastStatus", status.LastStatus);

                var affectedRows = command.ExecuteNonQuery();
                return affectedRows;
            }
        }
    }

    public class ServiceHealthHistoryRepository : IServiceHealthHistoryRepository
    {
        string connectionString = "Server=tcp:servicehealth-dev.database.windows.net,1433;Initial Catalog=servicehealthd;Persist Security Info=False;" +
        "User ID=rddag;Password=Lyreco2018;" +
        "MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";


        public int Create(ServiceHealthDbModel status)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandType = System.Data.CommandType.Text;
                command.CommandText = @"
                INSERT INTO [dbo].[ServiceHealthHistory]
                       (
                        [TimestampUtc]
                       ,[ServiceId]
                       ,[ServiceName]
                       ,[Description]
                       ,[Location]
                ) VALUES (
                        @LastPing
                       ,@ServiceId
                       ,@ServiceName
                       ,@Description
                       ,@Location
	                );";

                command.Parameters.AddWithValue("@LastPing", status.LastPing);
                command.Parameters.AddWithValue("@ServiceId", status.ServiceId);
                command.Parameters.AddWithValue("@ServiceName", status.ServiceName);
                command.Parameters.AddWithValue("@Description", status.Description);
                command.Parameters.AddWithValue("@Location", status.Location);

                var affectedRows = command.ExecuteNonQuery();
                return affectedRows;
            }
        }
    }
}