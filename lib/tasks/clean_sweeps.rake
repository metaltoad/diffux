#require 'snapshot'
require_relative '../../app/workers/snapshot_worker.rb'
require_relative '../../app/workers/snapshot_comparer_worker.rb'


namespace :sweeps do
  #desc "Sweeps"
  task :clean => :environment do

    # find our failed snapshots
    missing_snapshots = Snapshot.where("accepted_at is null and rejected_at is null ")
    missing_snapshots.each do |snap|

      # use imagemagick to count the colors in each snapshot (phantomjs will return a 1 color image if it failed)
      cmd = "identify -format %k " + snap.image.path
      
      colors = %x(#{cmd})
      if colors.to_i < 2
        retake = true
      else
        retake = false
      end

      if retake
        #taken from sweeps_controller
        snap.image                = nil
        snap.accepted_at          = nil
        snap.rejected_at          = nil
        snap.snapshot_diff.try(:destroy!)
        snap.snapshot_diff        = nil
        snap.save!

        snap.take_snapshot
      end
    end

    #actually missing snaps.
    missing_snapshots = Snapshot.where ( "image_file_size is null")
    missing_snapshots.each do |snap|

      #taken from sweeps_controller
      snap.image                = nil
      snap.accepted_at          = nil
      snap.rejected_at          = nil
#      snap.image_file_size      = 514
      snap.snapshot_diff.try(:destroy!)
      snap.snapshot_diff        = nil
      snap.save!

      snap.take_snapshot
    end

    # find snaps that need to be recompared.
    missing_diffs = Snapshot.where("snapshot_diff_id is null ")
    missing_diffs.each do |snap|
      if snap.compare?
        SnapshotComparerWorker.perform_async(snap.id)
      end
    end

  end
end


#task :clean_sweeps do
#   puts "Kicking off a Worker"
#   SnapshotComparerWorker.perform_async(130)
#   sleep(1)
#   puts "done"
#end


