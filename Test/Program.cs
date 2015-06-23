using System;

namespace Test
{
    class Program
    {
        private static GisGmp.RequestManager requestQuery = new GisGmp.RequestManager();

        static void Main(string[] args)
        {
            var gisgmpServiceTimer = new System.Timers.Timer(3000);
            gisgmpServiceTimer.Elapsed += gisgmpServiceTimer_Elapsed;
            gisgmpServiceTimer.AutoReset = true;

            gisgmpServiceTimer.Enabled = true;

            Console.ReadKey();
        }

        static void gisgmpServiceTimer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            requestQuery.SendNextRequest();
            Console.WriteLine("Tik");
        }
    }
}
