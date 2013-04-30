# Main:

require 'zlib'
require 'archive'
require 'cons_p_p_log'

# Create a reference source:
arc = Archive.new

# The logfile. This is gzipped because otherwise it's
# more than 900MB in size:
logfile=ENV['HOME'] + "/cons_pp_0616_log.txt.gz"

# Required patterns:
#
# Log_0   2009-05-02T01:32:11 Preproc 4.7: Opening Telemetry file /isdc/arc/pck_1/0624/tm2007112417482800.fits
#
tmfile_pattern=Regexp::compile('.* Preproc 4\.7: Opening Telemetry file /isdc/arc/pck_1/(.*?)$')
# Marker for the rev counter:
current_rev = 0
content_cache=[]

begin
  # Create a normal IO object and pass it to a block where
  # the Zlib::GzipReader class can read it:
  revs=Hash.new()

  File.open(logfile) do |f|
    gz = Zlib::GzipReader.new(f)
    # Loop over lines:
    while line = gz.gets()
      line.chomp!

      if mdata = tmfile_pattern.match(line)
        # Extract the rev number from the file string:
        revno,tmfile=mdata[1].split("/")
        # If current_rev is 0, store the first real rev number:
        if current_rev == 0
          current_rev = revno
          # Create the first entry in the revs hash:
          revs[current_rev] = ConsPPLog.new(current_rev,tmfile)
          if content_cache.size > 0
            # Transfer the contents of the cache to the object:
            # FIXME: Handle passing of arrays to the content= method
            revs[current_rev].content=content_cache
            content_cache=[]
          end
        elsif current_rev == revno
          # Same revolution number so just track the files:
          revs[current_rev].tmfile=tmfile
        else          
          if content_cache.size > 0
            # Transfer the contents of the cache to the object. This will save content from previous revolution
            # as we now have the first match to the new revolution number:
            revs[current_rev].content=content_cache
            content_cache=[]
          end
          # Here we create a new entry for the new revolution:
          current_rev = revno
          # Create the first entry in the revs hash:
          revs[current_rev] = ConsPPLog.new(current_rev,tmfile)
        end
      else
        # Here go the other lines. Must account for the initial case
        # where there isn't yet an object stored but there is log content:
        content_cache << line
      end

    end
    gz.close
    # Check that the correct number of files have been parsed for each rev.
    # The block gets the revolution number and a ConsPPLog object through which
    # the array of files for the rev can be accessed:
    revs.each_pair do |r,o|
      nfgot=o.tmfiles.size
      unless arc.check_rev(r, nfgot) == true
        nfexp=arc.nfiles(r)
        print "\nWARN: Revolution #{r} only read #{nfgot} files from #{nfexp}\n"
      end
    end
    print "N_rev = #{revs.size}\n"
  end
# Handle exeptions:
rescue Zlib::GzipFile::NoFooter => err
  print($stderr," Zlib::GzipFile::NoFooter: #{err}\n")
  exit(140)
rescue Zlib::GzipFile::CRCError => err
  print($stderr," Zlib::GzipFile::CRCError: #{err}\n")
  exit(141)
rescue Zlib::GzipFile::LengthError => err
  print($stderr," Zlib::GzipFile::LengthError: #{err}\n")
  exit(142)
rescue NoMethodError => err
  print($stderr," NoMethodError: #{err}\n")
  exit(150)
rescue => err
  print($stderr," main: Unknown error: #{err}\n")
  exit(150)
end