// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   Dec 15, 2009  thibautc  Creation
//
using build
**
** Build: javaBuilder
**
class Build : BuildPod
{

  new make()
  {
    podName = "netColarJar"
    summary = "Utility to build standalone java app(jar) from a Fantom app pod(s)."
    depends = ["sys 1.0.64+", "build 1.0+", "fanr 1.0+", "web 1.0+"]
    version = Version("0.1.2")
    srcDirs = [`fan/`]
    javaDirs = [`java/`]
    resDirs = [,]
  }

}