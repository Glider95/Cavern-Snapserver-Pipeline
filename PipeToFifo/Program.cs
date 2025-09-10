using System;
using System.IO;
using System.IO.Pipes;
using System.Threading;

class PipeToFifo {
    static void Main(string[] args) {
        if (args.Length < 1) {
            Console.WriteLine("Usage: PipeToFifo <fifo_path>");
            return;
        }
        string fifoPath = args[0];
        const string pipeName = "cavern-audio-output";

        Console.WriteLine($"[PipeToFifo] Reading from pipe '{pipeName}' and writing to FIFO '{fifoPath}'.");

        try {
            using var pipe = new NamedPipeClientStream(".", pipeName, PipeDirection.In);

            Console.WriteLine("[PipeToFifo] Attempting to connect to audio processor...");
            int attempts = 0;
            while (!pipe.IsConnected && attempts < 20) { // Retry for 10 seconds
                try {
                    pipe.Connect(500); // 500ms timeout
                } catch (TimeoutException) {
                    // Expected timeout, just retry
                    attempts++;
                }
            }

            if (!pipe.IsConnected) {
                Console.WriteLine("[PipeToFifo] ERROR: Could not connect to the audio processor pipe. Timed out.");
                return;
            }
            
            Console.WriteLine("[PipeToFifo] Connected successfully.");

            using var fifo = new FileStream(fifoPath, FileMode.Open, FileAccess.Write);
            pipe.CopyTo(fifo);
        } catch (Exception ex) {
            Console.WriteLine($"[PipeToFifo] ERROR: {ex.Message}");
        }
        Console.WriteLine("[PipeToFifo] Finished.");
    }
}

