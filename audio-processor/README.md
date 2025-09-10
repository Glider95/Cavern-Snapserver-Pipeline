# Audio Processor

This project is an audio processing application that converts various audio formats, including Dolby, into PCM (Pulse Code Modulation) format. It is designed to read audio streams from input sources and output the converted PCM streams.

## Project Structure

```
audio-processor
├── src
│   ├── Program.cs         # Entry point of the application
│   └── AudioConverter.cs  # Contains the AudioConverter class for audio conversion
├── audio-processor.csproj  # Project file for build configurations
└── README.md               # Documentation for the project
```

## Getting Started

### Prerequisites

- .NET SDK (version 5.0 or later)
- A compatible audio input stream (Dolby or non-Dolby)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/audio-processor.git
   cd audio-processor
   ```

2. Restore the project dependencies:
   ```
   dotnet restore
   ```

### Running the Application

To run the application, use the following command:

```
dotnet run --project audio-processor.csproj
```

### Usage

The application will read from an input audio stream and convert it to PCM format. You can modify the `Program.cs` file to specify the input and output streams as needed.

### Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

### License

This project is licensed under the MIT License. See the LICENSE file for more details.