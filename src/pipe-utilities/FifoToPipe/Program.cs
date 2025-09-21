using System;
using System.IO;
using System.IO.Pipes;

class FifoToPipe {
    static void Main(string[] args) {
        string fifoPath = args.Length > 0 ? args[0] : "/tmp/snapcast-in";
        using var fifo = File.OpenRead(fifoPath);
        using var pipe = new NamedPipeClientStream(".", "cavern-audio-input", PipeDirection.Out);
        pipe.Connect();
        fifo.CopyTo(pipe);
    }
}
