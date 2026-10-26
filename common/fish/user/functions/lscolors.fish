function lscolors --description 'Show 256 terminal colors'
    for i in (seq 0 255)
        printf "\033[48;5;%sm %3d \033[0m" "$i" "$i"
        if test (math "($i + 1) % 16") -eq 0
            echo
        end
    end
end
