function rm --wraps trash --description 'Move files to trash instead of removing them'
    trash -v $argv
end
