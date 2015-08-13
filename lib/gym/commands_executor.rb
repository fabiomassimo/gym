module Gym
  # Executes commands and takes care of error handling and more
  module CommandsExecutor
    # @param command [String] The command to be executed
    # @param print_all [Boolean] Do we want to print out the command output while building?
    #   If set to false, nothing will be printed
    # @param error [Block] A block that's called if an error occurs
    # @return [String] All the output as string
    def self.execute(command: nil, print_all: false, error: nil)
      print_all = true if $verbose

      output = []
      command = command.join(" ")
      Helper.log.info command.yellow.strip unless Gym.config[:silent]

      puts "\n-----".cyan if print_all

      last_length = 0
      begin
        PTY.spawn(command) do |stdin, stdout, pid|
          stdin.each do |l|
            line = l.strip # strip so that \n gets removed
            output << line

            next unless print_all

            current_length = line.length
            spaces = [last_length - current_length, 0].max
            print((line + " " * spaces + "\r").cyan)
            last_length = current_length
          end
          Process.wait(pid)
          puts "-----\n".cyan if print_all
        end
      rescue => ex
        # This could happen when the environment is wrong:
        # > invalid byte sequence in US-ASCII (ArgumentError)
        output << ex.to_s
        o = output.join("\n")
        puts o
        error.call(o)
      end

      # Exit status for build command, should be 0 if build succeeded
      # Disabled Rubocop, since $CHILD_STATUS just is not the same
      if $?.exitstatus != 0 # rubocop:disable Style/SpecialGlobalVars
        o = output.join("\n")
        puts o # the user has the right to see the raw output
        error.call(o)
      end
    end
  end
end
