# Class to represent a logfile:
class ConsPPLog
  def initialize(rev,tmfile)
    @rev=rev
    @tmfiles=[ tmfile ]
    @content=Array::new()
  end
  
  attr_reader :rev, :tmfiles

  def content=(l)
    print "."
    @content << l
  end

  def tmfile=(f)
    @tmfiles << f
  end

end
