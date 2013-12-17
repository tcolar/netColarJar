// History:
//   Dec 15, 2009  thibautc  Creation
//
using build

**
** Build standalone Java jars (TODO: JNLP, wars).
** It basically build a jar with a minimal Fantom runtime and some pods
** The jar contains a Java launcher that does the following:
** - When the jar is run, it copies the Fantom runtime into a dir
** - Then the launcher starts a given Fantom program using that runtime.
**
class BuildJar : JdkTask
{
  ** Required: Destination file
  File destFile

  ** Required: Pod names to include, dependant pods will be resolved
  ** and added as well
  Str[] pods := [,]

  ** Required: Main class/method
  ** Ex: 'mypod::Main.main'
  ** Ex: 'mypod::Main' same as 'mypod::Main.main'
  ** Ex: 'mypod' same as 'mypod::Main.main'
  Str appMain

  ** Any extra files to be copied (to relative dest uri)
  ** Example : `./swt/swt.jar` : `lib/java/ext/swt.jar`
  Uri:Uri extraFiles := [:]

  ** Constructor
  new make(BuildScript script, |This|? f := null) : super(script)
  {
    if(f != null)
    {
      f(this)
    }
  }

  ** Build a standalone Jar (Containing a minimal Fantom runtime)
  override Void run()
  {
    File temp     := script.scriptDir + `temp/`
    File tempFantom     := temp + `fantom/`
    File tempLib    := tempFantom + `lib/`
    File tempFan    := tempLib + `fan/`
    File tempJava    := tempLib + `java/`
    File tempExt    := tempJava + `ext/`
    File tempLauncher    := temp + `fanjarlauncher/`
    File tempEtcSys    := tempFantom + `etc/sys/`
    manifest   := temp + `Manifest.mf`
    libFan     := script.devHomeDir + `lib/fan/`
    binDir     := script.devHomeDir + `bin/`
    libJavaDir := script.devHomeDir + `lib/java/`

    // make temp dirs
    temp.delete
    temp.create
    temp.deleteOnExit
    tempLib.create
    tempFan.create
    tempExt.create
    tempEtcSys.create

    // Add fan runtime
    log.info("Adding Fantom binaries: $binDir")
    binDir.copyInto(tempFantom)
    // etc/sys files needed for runtime
    File tz := script.devHomeDir + `etc/sys/timezones.ftz`
    tz.copyInto(tempEtcSys)
    File conf := script.devHomeDir + `etc/sys/config.props`
    conf.copyInto(tempEtcSys)
    File syntax := script.devHomeDir + `etc/syntax/`
    syntax.copyTo(tempEtcSys.parent+`syntax/`, ["overwrite" : true])
    // java libs
    log.info("Adding Fantom Java libraries $libJavaDir")
    libJavaDir.listFiles.each |File f| {f.copyInto(tempJava)}
    // add other libs requested by the user
    extraFiles.each |Uri to, Uri from|
    {
      File src := from.toFile
      File dest := tempFantom + to
      if(src.exists)
      {
        log.info("Adding Extra file: $src to $dest")
        src.copyTo(dest, ["overwrite":true])
      }
      else
      {
        throw Err("Extra file not found! : $src")
      }
    }
    // Add pods and their dependencies (recursively))
    buildPodList.each |Str podName|
    {
      log.info("Adding Fantom Pod: $podName")
      podFile := libFan + `${podName}.pod`
      podFile.copyInto(tempFan)
    }

    // Copy custom Java Launcher code
    thispod := libFan + `${this.typeof.pod.name}.pod`
    zip := Zip.open(thispod)
    zip.contents.each {
      if( ! it.isDir && it.path[0]=="fanjarlauncher")
      {
        it.copyInto(tempLauncher)
      }
    }
    zip.close

    // write manifest
    log.info("Write Manifest [${manifest.osPath}]")
    out := manifest.out
    out.printLine("Manifest-Version: 1.0")

    // Custom entry for the app "Main""
    out.printLine("Fantom-Main: $appMain")
    out.printLine("Main-Class: fanjarlauncher.Launcher")
    out.close

    // ensure jar target directory exists
    destFile.parent.create

    // jar up temp directory
    log.info("Jar [${destFile.osPath}]")
    Exec(script, [jarExe, "cfm", destFile.osPath, manifest.osPath, "-C", temp.osPath, "."], temp).run
  }

  ** Build the list of pods required for this jar
  ** It starts with the pods listed in the "pods" array and adds all dependencies as well.
  internal Str[] buildPodList()
  {
    // always want the sys pod
    Str[] resPods := ["sys"]
    // Then add user specified pods and their dependencies
    pods.each |Str podName|
    {
      pod := Pod.find(podName)
      if(pod == null)
      {
        throw Err("Pod not found $podName")
      }
      else
        {
        // no duplicates
        if( ! resPods.contains(podName))
          {
          resPods.add(podName)
          resolveDeps(resPods, pod)
        }
      }
    }
    return resPods
  }

  ** Finds a pod Dependencies (other pods) and add them to results
  ** - Recursive
  internal Void resolveDeps(Str[] results, Pod pod)
  {
    pod.depends.each |Depend dep|
    {
      depPod := Pod.find(dep.name)
      if(depPod == null)
        {
        throw Err("Pod not found $pod.name")
      }
      else if( ! dep.match(depPod.version))
        {
        throw Err("Pod version mismatch for $pod.name . Required: $dep.version , Found: $depPod.version")
      }
      else
        {
        // No duplicates
        if( ! results.contains(dep.name))
          {
          results.add(dep.name)
          // recurse into pod dependencies
          resolveDeps(results, depPod)
        }
      }
    }
  }
}


