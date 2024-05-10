# File: Minesweeper.rb
# Author : Andreas Saméus
# Date: 2024-05-10
# Description: A game of minesweeper

#sets up the screen and its traits
require "ruby2d"
set title: "Minesweeper"
set background: "gray"


# Class for creating tiles
# Attributes:
# bomb: boolean for if a tile is a bomb or not
# flagged: boolean for if the tile is flagged
# bombs_close: the amount of bombs around the tile
# revealed: boolean for if the tile has been clicked

class Bomb
    attr_accessor :bomb, :flagged, :bombs_close, :revealed

    def initialize(bomb, bombs_close, flagged = false, revealed = false)
        @bomb = bomb
        @flagged = flagged
        @bombs_close = bombs_close
        @revealed = revealed
    end

    #method for getting the file path for a tile
    # No parameters
    # Returns: The file path for a tile

    def sprite_path
        if revealed
            if bomb == false
                if bombs_close == 0
                    return "Sprites//TileEmpty.png"
                elsif bombs_close == 1
                    return "Sprites//Tile1.png"
                elsif bombs_close == 2
                    return "Sprites//Tile2.png"
                elsif bombs_close == 3
                    return "Sprites//Tile3.png"
                elsif bombs_close == 4
                    return "Sprites//Tile4.png"
                elsif bombs_close == 5
                    return "Sprites//Tile5.png"
                elsif bombs_close == 6
                    return "Sprites//Tile6.png"
                elsif bombs_close == 7
                    return "Sprites//Tile7.png"
                elsif bombs_close == 8
                    return "Sprites//Tile8.png"
                end
            elsif bomb
                return "Sprites//TileExploded.png"
            end
        elsif flagged
            return"Sprites//TileFlag.png"
        else
            return "Sprites//TileUnknown.png"
        end
    end

    # method for changing if a tile has been flagged or not
    # No parameters
    # No Returns
    def flag
        @flagged = !@flagged
    end

    # method for revealing a tile
    # No parameters
    # No Returns
    def reveal
        @revealed = true
    end

    # method for updating how many bombs are close to a tile
    # Parameters:
    # minefield: the minefield
    # No returns
    def update_bombs_close(minefield)
        row_index, col_index = find_position(minefield)
        bombs_count = count_bombs(minefield, row_index, col_index)
        @bombs_close = bombs_count
    end

    # method for getting the position of a tile to help the update_bombs_close method
    # Parameters:
    # minefield: the minefield
    # Returns: i and col_index which represents the row index and col index of a tile
    def find_position(minefield)
        for i in 0...minefield.length
            row = minefield[i]
            col_index = row.index(self)
            if col_index
                return [i, col_index] 
            end
        end
    end

    # method for counting how maby bombs are close to a tile
    # Parameters:
    # minefield: the minefield with all tiles
    # row_index: the row a tile is on
    # col_index: the column a tile is on
    # Returns: integer that represents the bombs colse to a tile
    def count_bombs(minefield, row_index, col_index)
        bombs_count = 0
        for r in (row_index - 1)..(row_index + 1)
            if r < 0 || r >= minefield.length
                next 
            end

            for c in (col_index - 1)..(col_index + 1)
                if c < 0 || c >= minefield[r].length || (r == row_index && c == col_index)
                    next 
                end

                if minefield[r][c].bomb
                 bombs_count += 1 
                end
            end
        end
        bombs_count
    end
end

#initializes global variables
$minefield = []
$row_length = 0
$column_length = 0
$bomb_amount = 0
$first_click = true

# Generates the minefield based on the coordinates of the first click
# Parameters:
# x: the click x coordinate
# y: the click y coordinate
# No Returns 

def generate_minefield(x,y)
    x = x/16
    y = y/16

    flat_minefield = Array.new($row_length * $column_length) { Bomb.new(false, 0) }

    offsets = [
        [-1, -1], [-1, 0], [-1, 1],
        [0, -1],  [0, 0],  [0, 1],
        [1, -1],  [1, 0],  [1, 1]
    ]

    # removes the click and 8 tiles around from the algorithm of randomizing bombs
    bomb_indices = (0...flat_minefield.length).to_a
    for offset in offsets
        nx = x + offset[1]
        ny = y + offset[0]

        index = (nx + (ny * $column_length))
        # Check if the neighboring cell is within bounds
        if nx >= 0 && nx < $column_length && ny >= 0 && ny < $row_length
            bomb_indices_index = bomb_indices.index(index)
            bomb_indices.delete_at(bomb_indices_index)
        end
    end

    # randomizes the positioning of bombs
    bomb_indices = bomb_indices.sample($bomb_amount)
    for index in bomb_indices
         
        flat_minefield[index] = Bomb.new(true, 0)
    end

    # creates a 2d array based on the flat_minefield
    slice_index = 0
    for i in 0...$row_length
        row_array = []
        for j in 0...$column_length
            row_array << flat_minefield[slice_index]
            slice_index += 1
        end
        $minefield << row_array
    end

    # changes the bombs_close from 0 to the correct amount
    update_bombs_close($minefield)
end

# goes through the minefield and updates the bombs_close
# Parameters:
# minefield: the minefield
# No Returns
def update_bombs_close(minefield)
    for row in minefield
        for cell in row
            cell.update_bombs_close(minefield)
        end
    end
end

# goes through the minefield and updates it on the board
# No Parameters
# No Returns

def draw_minefield
    clear 
    for i in 0...$minefield.length
        row = $minefield[i]
        for j in 0...row.length 
            cell = row[j]
            x = j * 16 
            y = i * 16 

            # Draw the cell's sprite
            Image.new(cell.sprite_path, x: x, y: y, width: 16, height: 16)
        end
    end
end

# Draws the board before the first click
# No Parameters
# No Returns

def draw_dummy_minefield
    for i in 0...$column_length
        for j in 0...$row_length 
            x = i * 16 
            y = j * 16 

            # Draw the cell's sprite
            Image.new("Sprites//TileUnknown.png", x: x, y: y, width: 16, height: 16)
        end
    end
end

# reveals the clicked tile and also surounding tiles if the neighbouring tiles have zero bombs_close
# Parameters:
# x: the x coordinate on the board
# y: the y coordinate on the board
# Returns: empty

def reveal(x,y)
    tile = $minefield[y][x]

    # If the cell is already revealed or flagged, return
    if tile.revealed || tile.flagged
        return
    end

    # Reveal the current cell
    tile.reveal

    # If the cell has no bombs close, recursively reveal neighboring cells
    if tile.bombs_close == 0 && !tile.bomb
        # Define offsets for neighboring cells
        offsets = [
            [-1, -1], [-1, 0], [-1, 1],
            [0, -1],           [0, 1],
            [1, -1],  [1, 0],  [1, 1]
        ]

        # Iterate over neighboring cells
        for offset in offsets
            nx = x + offset[1]
            ny = y + offset[0]

            # Check if the neighboring cell is within bounds
            if nx >= 0 && nx < $minefield[0].length && ny >= 0 && ny < $minefield.length
                # Reveal the neighboring cell if it's not already revealed
                if !$minefield[ny][nx].revealed
                    reveal(nx, ny)
                end
            end
        end
    end

    # if the clicked tile is a bomb reveal all bombs and end game
    if tile.bomb
        for column in $minefield
            for cell in column
                if cell.bomb
                    cell.reveal
                end
            end
        end
        puts "You Lose!"
        close
    end        

end

# handles the click to reveal tiles and flag tiles
# Parameters:
# event: the information about the click
# No Returns

def handle_click(event)
    x = event.x/16 
    y = event.y/16
    
    #reveals tiles when left button is clicked, flags when right button is clicked
    case event.button
    when :left
        reveal(x,y)
    when :right
        if !$minefield[y][x].revealed
            $minefield[y][x].flag
        end
    end

    draw_minefield

    tiles_cleared = 0
    for index in $minefield
        for tile in index
            if !tile.bomb && tile.revealed
                tiles_cleared +=1
            end
        end
    end
    # checks if all the tiles that arent bombs have been cleared and ends the game if the player has won
    if tiles_cleared == ($row_length * $column_length)-$bomb_amount
        puts "Congratulations you win!"
        close
    end

end

# Main function that shows the windows and uses previous functions
# No Parameters
# No Returns

def main
    puts "Enter column length, row length, and bomb amount:"
    $row_length = gets.to_i
    $column_length = gets.to_i
    $bomb_amount = gets.to_i



    set width: $column_length * 16
    set height: $row_length * 16
    draw_dummy_minefield

    on :mouse_down do |event|
        if $first_click
            generate_minefield(event.x,event.y)
            handle_click(event)
            $first_click = false
        else
            handle_click(event)
        end
    end

    show
end

main
