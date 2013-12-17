## Single jar

Utility to create standalone Fantom applications as a single self executing Jar file.
This is different than the "DistJar" Fantom option because as it
will expand and create a proper fantom runtime folder upon execution
which tend to have less limitations and work better than JarDist.

### Usage:

Use the provided BuildJar Task to create the jar from your app build script

Example:

    using build
    using netColarJar

    class build : BuildPod
    {
    // ... your app description
    }

    @Target { help = "Build single jar" }
    Void jar()
    {
      BuildJar(this){
        destFile = `./mycoolapp.jar`
        appMain = "mycoolapp::Main"
        pods = ["mycoolapp"] // Dependency get pulled automatically
        //extraFiles = [`./swt.jar` : `lib/java/ext/${dir.name}/swt.jar`]
      }.run
    }
  }

Build the jar:

    fan build.fan jar

Once done the app can be run simply using JNLP or manually:

    java -jar mycoolapp.jar


