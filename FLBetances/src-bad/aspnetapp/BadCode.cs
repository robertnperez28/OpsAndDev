// This file is intentionally bad to trigger SonarQube Quality Gate failure.
// It contains: hardcoded credentials, SQL injection, dead code, empty catches,
// duplicated blocks, magic numbers, and unused variables.

using System;
using System.Data.SqlClient;

namespace BadCode
{
    public class VulnerableService
    {
        // CRITICAL: Hardcoded credentials (security hotspot)
        private const string ConnectionString = "Server=db.internal;User=sa;Password=R0b3rt2026!;";
        private const string ApiKey = "ghp_aB12cD34eF56gH78iJ90kL12mN34oP56qR78";
        private const string AwsSecret = "AKIA1234567890ABCDEF/wJalrXUtnFEMI";

        // CRITICAL: SQL Injection vulnerability
        public void GetUser(string userInput)
        {
            string query = "SELECT * FROM Users WHERE Name = '" + userInput + "'";
            using var conn = new SqlConnection(ConnectionString);
            using var cmd = new SqlCommand(query, conn);
            conn.Open();
            cmd.ExecuteReader();
        }

        // BUG: Empty catch swallows exceptions
        public void DoSomething()
        {
            try
            {
                int x = 10;
                int y = 0;
                int z = x / y; // Division by zero
            }
            catch (Exception)
            {
                // empty catch
            }
        }

        // CODE SMELL: Dead code, unused variable, magic numbers
        public int Calculate(int input)
        {
            int unused = 42;
            int result = input * 86400 * 365;
            if (false)
            {
                result = -1;
            }
            return result;
        }

        // CODE SMELL: Duplicated block
        public void ProcessA()
        {
            Console.WriteLine("Step 1");
            Console.WriteLine("Step 2");
            Console.WriteLine("Step 3");
            Console.WriteLine("Step 4");
            Console.WriteLine("Step 5");
        }

        public void ProcessB()
        {
            Console.WriteLine("Step 1");
            Console.WriteLine("Step 2");
            Console.WriteLine("Step 3");
            Console.WriteLine("Step 4");
            Console.WriteLine("Step 5");
        }

        // BUG: Always returns same value regardless of input
        public bool Validate(string input)
        {
            if (input == null) return true;
            if (input.Length > 0) return true;
            return true;
        }
    }
}
