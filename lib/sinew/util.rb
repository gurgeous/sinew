require "digest/md5"
require "etc"
require "fileutils"

module Sinew
  # Helper module for executing commands and printing stuff
  # out.
  #
  # The general idea is to only print commands that are actually
  # interesting. For example, mkdir_if_necessary won't print anything
  # if the directory already exists. That way we can scan output and
  # see what changes were made without getting lost in repetitive
  # commands that had no actual effect.
  module Util
    class RunError < StandardError ; end

    extend self
    
    RESET   = "\e[0m"
    RED     = "\e[1;37;41m"
    GREEN   = "\e[1;37;42m"
    YELLOW  = "\e[1;37;43m"
    BLUE    = "\e[1;37;44m"
    MAGENTA = "\e[1;37;45m"
    CYAN    = "\e[1;37;46m"

    #
    # running commands
    #

    # Make all commands echo before running.
    def run_verbose!
      @run_verbose = true
    end
    
    # Run a command, raise an error upon failure. Output goes to
    # $stdout/$stderr.
    def run(command, args = nil)
      line = nil
      if args
        args = args.map(&:to_s)
        line = "#{command} #{args.join(" ")}"
        vputs line
        system(command, *args)
      else
        line = command
        vputs line
        system(command)
      end
      if $? != 0
        if $?.termsig == Signal.list["INT"]
          raise "#{line} interrupted"
        end
        raise RunError, "#{line} failed : #{$?.to_i / 256}"
      end
    end

    # Like mkdir -p. Optionally, set the owner and mode.
    def mkdir(dir, owner = nil, mode = nil)
      FileUtils.mkdir_p(dir, :verbose => verbose?)
      chmod(dir, mode) if mode
      chown(dir, owner) if owner
    end

    # mkdir only if the directory doesn't already exist. Optionally,
    # set the owner and mode.
    def mkdir_if_necessary(dir, owner = nil, mode = nil)
      mkdir(dir, owner, mode) if !(File.exists?(dir) || File.symlink?(dir))
    end

    # rm a dir and recreate it.
    def rm_and_mkdir(dir)
      raise "don't do this" if dir == ""
      run "rm -rf #{dir} && mkdir -p #{dir}"
    end

    # Are two files different?
    def different?(a, b)
      !FileUtils.compare_file(a, b)
    end

    # Copy file or dir from src to dst. Optionally, set the mode and
    # owner of dst.
    def cp(src, dst, owner = nil, mode = nil)
      FileUtils.cp_r(src, dst, :preserve => true, :verbose => verbose?)
      if owner && !File.symlink?(dst)      
        chown(dst, owner) 
      end
      if mode
        chmod(dst, mode)
      end
    end

    # Copy file or dir from src to dst, but create the dst directory
    # first if necessary. Optionally, set the mode and owner of dst.
    def cp_with_mkdir(src, dst, owner = nil, mode = nil)
      mkdir_if_necessary(File.dirname(dst))
      cp(src, dst, owner, mode)
    end

    # Copy file or dir from src to dst, but ONLY if dst doesn't exist
    # or has different contents than src. Optionally, set the mode and
    # owner of dst.
    def cp_if_necessary(src, dst, owner = nil, mode = nil)
      if !File.exists?(dst) || different?(src, dst)
        cp(src, dst, owner, mode)
        true
      end
    end

    # Move src to dst. Because this uses FileUtils, it works even if
    # dst is on a different partition.
    def mv(src, dst)
      FileUtils.mv(src, dst, :verbose => verbose?)
    end

    # Move src to dst, but create the dst directory first if
    # necessary.
    def mv_with_mkdir(src, dst)
      mkdir_if_necessary(File.dirname(dst))
      mv(src, dst)
    end

    # Chown file to be owned by user.
    def chown(file, user)
      user = user.to_s
      # who is the current owner?
      @uids ||= {}
      @uids[user] ||= Etc.getpwnam(user).uid
      uid = @uids[user]
      if File.stat(file).uid != uid
        run "chown #{user}:#{user} '#{file}'"        
      end
    end

    # Chmod file to a new mode.
    def chmod(file, mode)
      if File.stat(file).mode != mode
        FileUtils.chmod(mode, file, :verbose => verbose?)      
      end
    end

    # rm a file
    def rm(file)
      FileUtils.rm(file, :force => true, :verbose => verbose?)
    end

    # rm a file, but only if it exists.
    def rm_if_necessary(file)
      if File.exists?(file)
        rm(file)
        true
      end
    end

    # Create a symlink from src to dst.
    def ln(src, dst)
      FileUtils.ln_sf(src, dst, :verbose => verbose?)
    end

    # Create a symlink from src to dst, but only if it hasn't already
    # been created.
    def ln_if_necessary(src, dst)
      ln = false
      if !File.symlink?(dst)
        ln = true
      elsif File.readlink(dst) != src
        rm(dst)
        ln = true
      end
      if ln
        ln(src, dst)
        true
      end
    end

    # Touch a file
    def touch(file)
      FileUtils.touch(file)      
    end

    # A nice printout in green.
    def banner(s, color = GREEN)
      s = "#{s} ".ljust(72, " ")      
      $stderr.write "#{color}[#{Time.new.strftime('%H:%M:%S')}] #{s}#{RESET}\n"
      $stderr.flush
    end

    # Print a warning in yellow.
    def warning(msg)
      banner("Warning: #{msg}", YELLOW)
    end

    # Print a fatal error in red, then exit.
    def fatal(msg)
      banner(msg, RED)
      exit(1)
    end

    # Generate some random text
    def random_text(len)
      chars = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a
      (1..len).map { chars[rand(chars.length - 1)] }.join("")
    end
    
    # Convert a string into something that could be a path segment
    def pathify(s)
      s = s.gsub(/^\//, "")
      s = s.gsub("..", ",")
      s = s.gsub(/[?\/&]/, ",")
      s = s.gsub(/[^A-Za-z0-9_.,=-]/) do |i|
        hex = i.unpack("H2").first
        "%#{hex}"
      end
      s = "_root_" if s.empty?
      s = s.downcase
      s
    end

    # checksum some text    
    def md5(s)
      Digest::MD5.hexdigest(s.to_s)
    end

    private

    # Returns true if verbosity is turned on.
    def verbose?
      @run_verbose ||= nil
    end

    def vputs(s)
      $stderr.puts s if verbose?
    end
  end
end
