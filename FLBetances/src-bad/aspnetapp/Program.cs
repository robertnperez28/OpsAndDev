// Minimal entry point. The real "bad code" lives in BadCode.cs
// and is analyzed by SonarQube to fail the Quality Gate.
namespace BadApp
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            System.Console.WriteLine("Bad code app - intentionally low quality for Sonar gate demo");
        }
    }
}
