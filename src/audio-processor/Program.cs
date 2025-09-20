using System;
using System.IO;
using System.IO.Pipes;
using System.Threading.Tasks;
using AudioProcessor;

public class Program {
    public static async Task Main(string[] args) {
        const string inputPipeName = "cavern-audio-input";
        const string outputPipeName = "cavern-audio-output";

        // Backward compatible arg parsing:
        // - If 2+ args: <outChannels> <codec>
        // - If 1 arg: <codec>, default outChannels=2
        // - Else defaults: outChannels=2, codec=eac3
        int outChannels = 2;
        string codec = "eac3";

        if (args.Length >= 2 && int.TryParse(args[0], out var ch)) {
            outChannels = ch;
            codec = args[1];
        } else if (args.Length == 1) {
            codec = args[0];
        }

        Console.WriteLine("Cavern Audio Processor");
        Console.WriteLine($"Input pipe: {inputPipeName}");
        Console.WriteLine($"Output pipe: {outputPipeName}");
        Console.WriteLine($"Out channels: {outChannels}, Codec: {codec}");

        try {
            using var inputPipe = new NamedPipeServerStream(inputPipeName, PipeDirection.In, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous);
            using var outputPipe = new NamedPipeServerStream(outputPipeName, PipeDirection.Out, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous);

            Console.WriteLine("Waiting for clients to connect...");
            var inputConnectionTask = inputPipe.WaitForConnectionAsync();
            var outputConnectionTask = outputPipe.WaitForConnectionAsync();
            await Task.WhenAll(inputConnectionTask, outputConnectionTask);
            Console.WriteLine("Input and output clients connected.");

            var converter = new AudioConverter(inputPipe, outputPipe);
            await converter.ProcessAsync(outChannels, codec);
        } catch (Exception ex) {
            Console.Error.WriteLine($"A pipe error occurred: {ex.Message}");
        }

        Console.WriteLine("Processing finished. Application will now exit.");
    }
}