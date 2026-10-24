function gitdotfiles --description 'Pull, commit, and push dotfile updates'
    dotfiles pull
    or begin
        echo "Error: Failed to pull changes"
        return 1
    end

    dotfiles status
    dotfiles add -u
    dotfiles commit -m "Updates from PC"
    or begin
        echo "Error: Failed to commit changes"
        return 1
    end

    dotfiles push
    or begin
        echo "Error: Failed to push changes"
        return 1
    end

    echo "Successfully synced dotfiles!"
end
