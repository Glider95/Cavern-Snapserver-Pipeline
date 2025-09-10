using System;
using System.IO;
using System.IO.Pipes;
using System.Threading.Tasks;

namespace AudioProcessor {
    public class AudioConverter {
        private readonly Stream input;
        private readonly Stream output;

        public AudioConverter(Stream input, Stream output) {
            this.input = input;
            this.output = output;
        }

        public async Task ProcessAsync(int outChannels, string codec) {
            await Task.Run(() => ProcessBridge(outChannels, codec));
        }

        void ProcessBridge(int outChannels, string codec) {
            Console.Error.WriteLine("[AudioProcessor] Starting CavernStream-compatible bridge...");
            try {
                using var pipe = new NamedPipeClientStream("CavernPipe");
                pipe.Connect();
                Console.Error.WriteLine("[AudioProcessor] Connected to CavernPipe.");

                // Handshake: [0]=bitDepth, [1]=codecA, [2..3]=outChannels(ushort), [4..7]=codecB(int)
                byte[] handshake = new byte[8];
                // The server expects a valid PCM bit depth here (bits per sample).
                // Use 16-bit output (most common / matches Snapserver's sampleFormat 48000:16:2).
                handshake[0] = 16;

                codec = (codec ?? "eac3").ToLowerInvariant();
                if (codec == "eac3" || codec == "ac3") {
                    handshake[1] = 24;                       // mandatory frames
                    BitConverter.GetBytes(64).CopyTo(handshake, 4); // update rate
                } else if (codec == "truehd") {
                    handshake[1] = 0;
                    BitConverter.GetBytes(0).CopyTo(handshake, 4);
                } else {
                    Console.Error.WriteLine($"[AudioProcessor] Unsupported codec: {codec}");
                    return;
                }
                BitConverter.GetBytes((ushort)outChannels).CopyTo(handshake, 2);

                // Debug: dump handshake bytes (hex) and selected codec/outChannels to stderr
                try {
                    Console.Error.Write("AudioProcessor: sending handshake:");
                    for (int i = 0; i < handshake.Length; ++i) {
                        Console.Error.Write($" {handshake[i]:X2}");
                    }
                    Console.Error.WriteLine($"  codec=\"{codec}\", outChannels={outChannels}");
                } catch (Exception) {
                    // ignore any logging error
                }

                pipe.Write(handshake, 0, handshake.Length);
                pipe.Flush();

                byte[] inBuf = new byte[20000];
                byte[] outBuf = new byte[65536];
                byte[] lenBuf = new byte[4];

                Console.Error.WriteLine("[AudioProcessor] Streaming loop started...");
                int frameCount = 0;

                while (true) {
                    int read = input.Read(inBuf, 0, inBuf.Length);
                    if (read == 0) break;

                    // to CavernPipe: [length][payload]
                    pipe.Write(BitConverter.GetBytes(read), 0, 4);
                    pipe.Write(inBuf, 0, read);
                    pipe.Flush();

                    // from CavernPipe: [length][payload]
                    if (!ReadExact(pipe, lenBuf, 4)) break;
                    int respLen = BitConverter.ToInt32(lenBuf, 0);
                    if (respLen <= 0) continue;

                    int remaining = respLen;
                    while (remaining > 0) {
                        int chunk = Math.Min(outBuf.Length, remaining);
                        if (!ReadExact(pipe, outBuf, chunk)) { remaining = 0; break; }
                        output.Write(outBuf, 0, chunk);
                        remaining -= chunk;
                    }
                    output.Flush();

                    if (++frameCount % 100 == 0) {
                        Console.Error.WriteLine($"[AudioProcessor] Frames: {frameCount}, last out {respLen} bytes");
                    }
                }

                Console.Error.WriteLine("[AudioProcessor] Streaming complete.");
            } catch (Exception ex) {
                Console.Error.WriteLine($"[AudioProcessor] ERROR: {ex.Message}");
                throw;
            }
        }

        static bool ReadExact(Stream s, byte[] buf, int count) {
            int off = 0;
            while (off < count) {
                int got = s.Read(buf, off, count - off);
                if (got == 0) return false;
                off += got;
            }
            return true;
        }
    }
}
