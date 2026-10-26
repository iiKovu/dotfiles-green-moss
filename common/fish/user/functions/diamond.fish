function diamond --description 'Clear paru cache and remove orphaned packages'
    sudo find /var/cache/pacman/pkg \
        -mindepth 1 -maxdepth 1 \
        -type d -name 'download-*' \
        -user alpm -empty -delete

    paru -Scc
    stone

    # sudo journalctl --vacuum-size=50M
end
