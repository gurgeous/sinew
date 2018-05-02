require 'fileutils'
require 'tempfile'

#
# This class handles the caching of http responses on disk.
#

module Sinew
  class Cache
    attr_reader :sinew

    def initialize(sinew)
      @sinew = sinew
    end

    def get(request)
      body = read_if_exist(body_path(request))
      return nil if !body

      head = read_if_exist(head_path(request))
      Response.from_cache(request, body, head)
    end

    def set(response)
      body_path = body_path(response.request)
      head_path = head_path(response.request)

      FileUtils.mkdir_p(File.dirname(body_path))
      FileUtils.mkdir_p(File.dirname(head_path))

      # write body, and head if necessary
      atomic_write(body_path, response.body)
      if head_necessary?(response)
        head = JSON.pretty_generate(response.head_as_json)
        atomic_write(head_path, head)
      end
    end

    def root_dir
      sinew.options[:cache]
    end
    protected :root_dir

    def head_necessary?(response)
      response.error? || response.redirected?
    end
    protected :head_necessary?

    def body_path(request)
      "#{root_dir}/#{request.cache_key}"
    end
    protected :body_path

    def head_path(request)
      body_path = body_path(request)
      dir, base = File.dirname(body_path), File.basename(body_path)
      "#{dir}/head/#{base}"
    end
    protected :head_path

    def read_if_exist(path)
      if File.exist?(path)
        IO.read(path, mode: 'r:UTF-8')
      end
    end
    protected :read_if_exist

    def atomic_write(path, data)
      tmp = Tempfile.new('sinew', encoding: 'UTF-8')
      tmp.write(data)
      tmp.close
      FileUtils.chmod(0o644, tmp.path)
      FileUtils.mv(tmp.path, path)
    ensure
      FileUtils.rm(tmp.path, force: true)
    end
    protected :atomic_write
  end
end
