# Class to represent a reference for revolution information:
class Archive
  def initialize
    @revolutions=Hash::new()
    tmfiles=ENV['HOME']+"/tmfiles-per-revno.txt"
    File.open(tmfiles,"r") do |f|
      while line = f.gets()
        line.chomp!
        elements=line.split(",")
        # Create four-digit key:
        rvk = sprintf("%04d",elements[0])
        if !@revolutions.has_key?(rvk)
          # Save the number of files as integer value:
          @revolutions[rvk] = elements[1].to_i
        end
      end
    end
  end

  # Method to return the number of files in the archive for a given revolution:
  def nfiles(revno)
    return @revolutions[revno] if @revolutions.has_key?(revno)
  end

  def check_rev(rev,nf)
    return true if self.nfiles(rev) == nf
  end

end
