function stone --description 'Remove orphaned pacman packages'
    set -l orphans (pacman -Qdtq 2>/dev/null)
    if test (count $orphans) -gt 0
        sudo pacman -Rns $orphans
    else
        echo "No orphaned packages found."
    end
end
