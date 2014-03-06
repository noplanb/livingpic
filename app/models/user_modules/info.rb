module UserModules
  module Info

    unloadable

    # Print the information on occasions
    def oc_i(type=:abbrev)
      relevant_occasions.map do |o|
        s = o.hs + participations.in(o).inject({}) do |h,p|
          key = type == :abbrev ? p.kind_abbrev : p.kind.to_s.capitalize
          h[key] ||= 0
          h[key] += 1
          h
        end.map { |k,v| "#{k}:#{v}"}.join(" ").enclose("(")
      end.join(", ")
    end

    # Print out the invites by occasion
    # occasion (id's of people invites)
    def in_i
      invites.map(&:occasion).uniq.map do |o|
        s = o.hs + (o.invites.by(self.id).map{|i| "#{i.id}:u#{i.invitee.id}"}*', ').enclose('(')
      end.join(",")
    end

    # Invitation targets
    def int_i
      invitings.map(&:occasion).uniq.map do |o|
        s = o.hs + (o.invites.to_u(self.id).map{|i| "#{i.id}:u#{i.inviter.id}"}*', ').enclose('(')
      end.join(",")      
    end

    # Print out the photo information for this user
    # Sorted by occasion, again
    def p_i
      photos.map(&:occasion).uniq.map do |o|
        s = o.hs + (o.photos.by(self.id).map(&:id)*',').enclose('(')
      end.join(",")
    end

    # Photo taggings by this user
    def pt_i
      photo_taggings.map(&:occasion).uniq.map do |o|
        s = o.hs + (o.photo_taggings.by(self.id).map{ |pt| "#{pt.id}:p#{pt.photo.id}:u#{pt.tagger_id}"}*',').enclose('(')
      end.join(",")      
    end

    # Photo taggings of this user
    def ptt_i
      photo_taggings_in.map(&:occasion).uniq.map do |o|
        s = o.hs + (o.photo_taggings.of(self.id).map{ |pt| "#{pt.id}:p#{pt.photo.id}:u#{pt.tagger_id}"}*',').enclose('(')
      end.join(",")      
    end

  end
end