# For compatibility, and because there is little chance of collision, we do not wrap this in our normal NoPlanB module
module Sanilog
  extend self
  def sanilog(msg, filename="sanilog")
    file = File.open(filename, "a")
    file.puts(msg)
    file.puts("")
    logger.debug("SANI_LOG: " + msg)
    file.close
  end
end