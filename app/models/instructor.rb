class Instructor < ActiveRecord::Base

  def uname
    self.name.split(" ").join.downcase
  end

end
