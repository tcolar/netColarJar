// History:
//  Dec 31 13 tcolar Creation
//

using fanr
using web

**
** FantomRunner
**
abstract class FantomRunner
{
  static const File FANTOM_HOME := Env.cur.homeDir

  Void main()
  {
    run()
  }

  // Implement to install your app and run your app as needed
  abstract Void run()

  ** Fetch a file via http and write it to target file
  Void fetchHttp(Uri what, File to)
  {
    to.create
    out := to.out
    wc := WebClient(what)
    try
    {
      buf := wc.getIn.readAllBuf//pipe(out)
      out.writeBuf(buf)
    }
    finally
    {
      out.flush
      out.close
      wc.close
    }
  }

  ** Install some pods usng fanr
  Void fetchFanr(Uri repoUri, Str[] pods)
  {
    args := ["install", "-errTrace", "-y", "-r", repoUri.toStr].addAll(pods)
    echo(args)
    fanr::Main().main(args)
  }

  ** Install some pods usng fanr sing authentication
  Void fetchFanrAuth(Uri repoUri, Str[] pods, Str user, Str password)
  {
    fanr::Main().main(["install", "-errTrace", "-y", "-r",repoUri, "-u", user, "-p", password].addAll(pods))
  }
}