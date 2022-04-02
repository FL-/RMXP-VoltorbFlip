################################################################################
# "Voltorb Flip" mini-game
# By KitsuneKouta
# Adapted by FL
#-------------------------------------------------------------------------------
# Run with:      $scene = Scene_VoltorbFlip.new
################################################################################
class Scene_VoltorbFlip
  def initialize(startValue=nil)
    @startValue=startValue
    @startValue||=1
  end  
  
  # When this setting is true, multiply the 2/3 values found, when false sum.
  MULTIPLYPOINTS=true
  
  # Multiply the money that you gain by this value
  MULTIPLYMONEY=1
  
  # Win bonus is a sum bonus for winning.
  WINBONUS=0
  
  # Quits when the player lose.
  QUITWHENLOSING=false
  
  # When the player press X and C, he quits.
  QUITALLOWED=true
  
  HIGH_SCORE_MAX_SIZE=10
  XSTART=128
  YSTART=48
  GAIN=64
  
  DIRECTORY="Graphics/Pictures/"
  
  def update
    pbUpdateSpriteHash(@sprites)
  end
    
  def main
    Graphics.transition
    @highScore = $game_party.flipHighScore
    while(@highScore.size<HIGH_SCORE_MAX_SIZE)
      @highScore.push(0)
    end  
    # Set initial level
    @level=1
    # Maximum and minimum total point values for each level
    @levelRanges=[[ 20, 50],[ 50, 100],[ 100, 200],[ 200, 350],
                  [350,600],[600,1000],[1000,2000],[2000,3500]]
    @firstRound=true
    pbNewGame
    loop do
      Graphics.update
      Input.update
      getInput
      if @quit
        break
      end
    end
    @sprites["curtainL"].angle=-180
    @sprites["curtainR"].angle=90
    # Draw curtain effect
    @sprites["curtainL"].visible=true
    @sprites["curtainR"].visible=true
    loop do
      @sprites["curtainL"].angle+=9
      # Fixes a minor graphical bug
      @sprites["curtainL"].y-=2 if @sprites["curtainL"].angle>=-90
      @sprites["curtainR"].angle-=9
      wait(1)
      if @sprites["curtainL"].angle>=-90
        break
      end
    end
    Graphics.freeze
    disposeSpriteHash(@sprites)
    @viewport.dispose
    $scene = Scene_Map.new
  end
  
  def pbNewGame
    # Initialize variables
    @sprites={}
    @cursor=[]
    @marks=[]
    @numbers=[]
    @voltorbNumbers=[]
    @points=0
    @index=[0,0]
    # [x,y,points,selected]
    @squares=[0,0,0,false]
    squareValues=[]
    total=1
    voltorbs=0
    for i in 0...25
      # Sets the value to 1 by default
      squareValues[i]=1
      # Sets the value to 0 (a voltorb) if # for that level hasn't been reached
      if voltorbs < 5+@level
        squareValues[i]=0
        voltorbs+=1
      # Sets the value randomly to a 2 or 3 if the total is less than the max
      elsif total<@levelRanges[@level-1][1]
        squareValues[i]=rand(2)+2
        total*=squareValues[i]
      end
      if total>(@levelRanges[@level-1][1])
        # Lowers value of square to 1 if over max
        total/=squareValues[i]
        squareValues[i]=1
      end
    end
    # Randomize the values a little
    for i in 0...25
      temp=squareValues[i]
      if squareValues[i]>1
        if rand(10)>8
          total/=squareValues[i]
          squareValues[i]-=1
          total*=squareValues[i]
        end
      end
      if total<@levelRanges[@level-1][0]
        if squareValues[i]>0
          total/=squareValues[i]
          squareValues[i]=temp
          total*=squareValues[i]
        end
      end
    end
    # Populate @squares array
    for i in 0...25
      if i%5==0
        x=i
      end
      r=rand(squareValues.length)
      @squares[i]=[(i-x).abs*GAIN+XSTART,(i/5).abs*GAIN+YSTART,squareValues[r],false]
      squareValues.delete_at(r)
    end
    pbCreateSprites
    # Display numbers (all zeroes, as no values have been calculated yet)
    for i in 0...5
      pbUpdateRowNumbers(0,0,i)
      pbUpdateColumnNumbers(0,0,i)
    end
    pbDrawShadowText(@sprites["text"].bitmap,8,16,118,26,
       ("Your coins"),Color.new(60,60,60),Color.new(150,190,170),1)
    pbDrawShadowText(@sprites["text"].bitmap,8,82,118,26,
       ("Earned coins"),Color.new(60,60,60),Color.new(150,190,170),1)
    pbDrawShadowText(@sprites["text"].bitmap,516,16,118,26,
       ("High Scores"),Color.new(60,60,60),Color.new(150,190,170),1)
    # Draw current level
    pbDrawShadowText(@sprites["level"].bitmap,8,150,118,28,
       ("Level #{@level}"),Color.new(60,60,60),Color.new(150,190,170),1)
    # Displays total and current coins
    pbUpdateCoins
    # Displays high score
    updateHighScores
    # Draw curtain effect
    if @firstRound
      loop do
        @sprites["curtainL"].angle-=5
        @sprites["curtainR"].angle+=5
        wait(1)
        if @sprites["curtainL"].angle<=-180
          break
        end
      end
    end
    @sprites["curtainL"].visible=false
    @sprites["curtainR"].visible=false
    @sprites["curtain"].opacity=0
    # Erase 0s to prepare to replace with values
    @sprites["numbers"].bitmap.clear
    # Reset arrays to empty
    @voltorbNumbers=[]
    @numbers=[]
    # Draw numbers for each row (precautionary)
    for i in 0...@squares.length
      if i%5==0
        num=0
        voltorbs=0
        j=i+5
        for k in i...j
          num+=@squares[k][2]
          if @squares[k][2]==0
            voltorbs+=1
          end
        end
      end
      pbUpdateRowNumbers(num,voltorbs,(i/5).abs)
    end
    # Reset arrays to empty
    @voltorbNumbers=[]
    @numbers=[]
    # Draw numbers for each column
    for i in 0...5
      num=0
      voltorbs=0
      for j in 0...5
        num+=@squares[i+(j*5)][2]
        if @squares[i+(j*5)][2]==0
          voltorbs+=1
        end
      end
      pbUpdateColumnNumbers(num,voltorbs,i)
    end
  end

  def pbCreateSprites
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["bg"]=Sprite.new(@viewport)
    @sprites["bg"].bitmap=Bitmap.new(DIRECTORY+"boardbg")
    @sprites["text"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    #pbSetSystemFont(@sprites["text"].bitmap)
    @sprites["text"].bitmap.font.size=26
    @sprites["level"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    #pbSetSystemFont(@sprites["level"].bitmap)
    @sprites["level"].bitmap.font.size=28
    @sprites["curtain"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["curtain"].z=99999
    @sprites["curtain"].bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0))
    @sprites["curtain"].opacity=0
    @sprites["curtainL"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["curtainL"].z=99999
    @sprites["curtainL"].x=256
    @sprites["curtainL"].angle=-90
    @sprites["curtainL"].bitmap.fill_rect(0,0,Graphics.width,Graphics.height,Color.new(0,0,0))
    @sprites["curtainR"]=BitmapSprite.new(Graphics.width,Graphics.height*2,@viewport)
    @sprites["curtainR"].z=99999
    @sprites["curtainR"].x=256
    @sprites["curtainR"].bitmap.fill_rect(0,0,Graphics.width,Graphics.height*2,Color.new(0,0,0))
    @sprites["cursor"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["cursor"].z=99998
    @sprites["icon"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["icon"].z=99997
    @sprites["mark"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["numbers"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["totalCoins"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["currentCoins"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["highScoreCoins"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["animation"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["animation"].z=99999
    for i in 0...6
      @sprites[i]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
      @sprites[i].z=99996
      @sprites[i].visible=false
    end
    # Creates images ahead of time for the display-all animation (reduces lag)
    icons=[]
    points=0
    for i in 0...3
      for j in 0...25
        points=@squares[j][2] if i==2
        icons[j]=[DIRECTORY+"tiles",@squares[j][0],@squares[j][1],320+(i*64)+(points*64),0,64,64]
      end
      icons.compact!
      pbDrawImagePositions(@sprites[i].bitmap,icons)
    end
    icons=[]
    for i in 0...25
      icons[i]=[DIRECTORY+"tiles",@squares[i][0],@squares[i][1],@squares[i][2]*64,0,64,64]
    end
    pbDrawImagePositions(@sprites[5].bitmap,icons)
    # Default cursor image
    @cursor[0]=[DIRECTORY+"cursor",XSTART,YSTART,0,0,64,64]
  end

  def getInput
    if Input.trigger?(Input::UP)
      $game_system.se_play($data_system.cursor_se)
      if @index[1]>0
        @index[1]-=1
        @sprites["cursor"].y-=GAIN
      else
        @index[1]=4
        @sprites["cursor"].y=GAIN*4
      end
    elsif Input.trigger?(Input::DOWN)
      $game_system.se_play($data_system.cursor_se)
      if @index[1]<4
        @index[1]+=1
        @sprites["cursor"].y+=GAIN
      else
        @index[1]=0
        @sprites["cursor"].y=0
      end
    elsif Input.trigger?(Input::LEFT)
      $game_system.se_play($data_system.cursor_se)
      if @index[0]>0
        @index[0]-=1
        @sprites["cursor"].x-=GAIN
      else
        @index[0]=4
        @sprites["cursor"].x=GAIN*4
      end
    elsif Input.trigger?(Input::RIGHT)
      $game_system.se_play($data_system.cursor_se)
      if @index[0]<4
        @index[0]+=1
        @sprites["cursor"].x+=GAIN
      else
        @index[0]=0
        @sprites["cursor"].x=0
      end
    elsif Input.trigger?(Input::A) # Mark mode
      for i in 0...@squares.length
        if @index[0]*GAIN+XSTART==@squares[i][0] && @index[1]*GAIN+YSTART==@squares[i][1] && @squares[i][3]==false
          Audio.se_play("Audio/SE/Voltorb Flip Mark")
        end
      end
      for i in 0...@marks.length+1
        if @marks[i]==nil
          @marks[i]=[DIRECTORY+"tiles",@index[0]*GAIN+XSTART,@index[1]*GAIN+YSTART,256,0,64,64]
        elsif @marks[i][1]==@index[0]*GAIN+XSTART && @marks[i][2]==@index[1]*GAIN+YSTART
          @marks.delete_at(i)
          @marks.compact!
          @sprites["mark"].bitmap.clear
          break
        end
      end
      pbDrawImagePositions(@sprites["mark"].bitmap,@marks)
      wait(2)
    elsif Input.trigger?(Input::C)
      # Display the tile for the selected spot
      icons=[]
      for i in 0...@squares.length
        if @index[0]*GAIN+XSTART==@squares[i][0] && @index[1]*GAIN+YSTART==@squares[i][1] && @squares[i][3]==false
          pbAnimateTile(@index[0]*GAIN+XSTART,@index[1]*GAIN+YSTART,@squares[i][2])
          @squares[i][3]=true
          # If Voltorb (0), display all tiles on the board
          if @squares[i][2]==0
            Audio.se_play("Audio/SE/Voltorb Flip Explosion")
            # Play explosion animation
            # Part1
            animation=[]
            for j in 0...3
              animation[0]=icons[0]=[DIRECTORY+"tiles",@index[0]*GAIN+XSTART,@index[1]*GAIN+YSTART,704+(64*j),0,64,64]
              pbDrawImagePositions(@sprites["animation"].bitmap,animation)
              wait(3)
              @sprites["animation"].bitmap.clear
            end
            # Part2
            animation=[]
            for j in 0...6
              animation[0]=[DIRECTORY+"explosion",@index[0]*GAIN+XSTART-32,@index[1]*GAIN+YSTART-32,j*128,0,128,128]
              pbDrawImagePositions(@sprites["animation"].bitmap,animation)
              wait(3)
              @sprites["animation"].bitmap.clear
            end
            # High Score
            updateHighScores(@points)
            # Unskippable text block, parameter 2 = wait time (corresponds to ME length)
            Audio.me_play("Audio/ME/Voltorb Flip Game Over")
            # Kernel.pbMessage(("\\me[Voltorb Flip Game Over]Oh no! You get 0 Coins!\\wtnp[50]"))
            pbShowAndDispose
            @sprites["mark"].bitmap.clear
            @quit=true if QUITWHENLOSING
            if @level>1
              # Determine how many levels to reduce by
              newLevel=0
              for j in 0...@squares.length
                if @squares[j][3]==true && @squares[j][2]>1
                  newLevel+=1
                end
              end
              if newLevel>@level
                newLevel=@level
              end
              if @level>newLevel
                @level=newLevel
                @level=1 if @level<1
                Audio.se_play("Audio/SE/Voltorb Flip Point")
                # Kernel.pbMessage("Dropped to Game Lv. #{@level}!")
              end
            end
            # Update level text
            @sprites["level"].bitmap.clear
            pbDrawShadowText(@sprites["level"].bitmap,8,150,118,28,"Level "+@level.to_s,Color.new(60,60,60),Color.new(150,190,170),1)
            @points=0
            pbUpdateCoins
            # Revert numbers to 0s
            @sprites["numbers"].bitmap.clear
            for i in 0...5
              pbUpdateRowNumbers(0,0,i)
              pbUpdateColumnNumbers(0,0,i)
            end
            if !@quit
              disposeSpriteHash(@sprites)
              @firstRound=false
              pbNewGame
            end
          else
            # Play tile animation
            animation=[]
            for j in 0...4
              animation[0]=[DIRECTORY+"flipAnimation",@index[0]*GAIN+XSTART-14,@index[1]*GAIN+YSTART-16,j*92,0,92,96]
              pbDrawImagePositions(@sprites["animation"].bitmap,animation)
              wait(3)
              @sprites["animation"].bitmap.clear
            end
            if (MULTIPLYPOINTS && @points==0) || (!MULTIPLYPOINTS && @squares[i][2]>1)
              @points+=@squares[i][2]*@startValue
              Audio.se_play("Audio/SE/Voltorb Flip Point")
            elsif @squares[i][2]>1
              @points*=@squares[i][2]
              Audio.se_play("Audio/SE/Voltorb Flip Point")
            end
            break
          end
        end
      end
    end
    count=0
    for i in 0...@squares.length
      if @squares[i][3]==false && @squares[i][2]>1
        count+=1
      end
    end
    pbUpdateCoins
    # Game cleared
    if count==0
      @sprites["curtain"].opacity=100
      Audio.me_play("Audio/ME/Voltorb Flip Win")
      @points+=WINBONUS*@startValue*@level
      pbUpdateCoins
      @sprites["curtain"].opacity=0
      pbShowAndDispose
      # Revert numbers to 0s
      @sprites["numbers"].bitmap.clear
      for i in 0...5
        pbUpdateRowNumbers(0,0,i)
        pbUpdateColumnNumbers(0,0,i)
      end
      @sprites["curtain"].opacity=100
      if @level<8
        @level+=1
        #Kernel.pbMessage(("Advanced to Game Lv. #{@level}!"))
#          if @firstRound
#            Kernel.pbMessage(("Congratulations!"))
#            Kernel.pbMessage(("You can receive even more Coins in the next game!"))
          @firstRound=false
#          end
      end
      # Kernel.pbMessage(("Board clear!\\wtnp[40]"))
#      Kernel.pbMessage(("You received #{@points} Coins!",$Trainer.name,@points))
      # Update level text
      @sprites["level"].bitmap.clear
      pbDrawShadowText(@sprites["level"].bitmap,8,150,118,28,("Level #{@level}"),Color.new(60,60,60),Color.new(150,190,170),1)
      $game_party.gain_gold(@points*MULTIPLYMONEY)
      updateHighScores(@points)
      @points=0
      pbUpdateCoins
      disposeSpriteHash(@sprites)
      pbNewGame
    elsif QUITALLOWED && Input.trigger?(Input::B)
      @sprites["curtain"].opacity=100
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          # Kernel.pbMessage(("You received #{@points} Coin(s)!"))
          $game_party.gain_gold(@points*MULTIPLYMONEY)
          updateHighScores(@points)
          @points=0
          pbUpdateCoins
          @sprites["curtain"].opacity=0
          pbShowAndDispose
          @quit=true
          break
        elsif Input.trigger?(Input::B) # Returns
          break
        end
      end
      @sprites["curtain"].opacity=0
    end
    # Draw cursor
    pbDrawImagePositions(@sprites["cursor"].bitmap,@cursor)
  end

  def pbUpdateRowNumbers(num,voltorbs,i)
    # Create and split a string for the number, with padded 0s
    zeroes=2-num.to_s.length
    numText=""
    for j in 0...zeroes
      numText+="0"
    end
    numText+=num.to_s
    numImages=numText.split(//)[0...2]
    for j in 0...2
      @numbers[j]=[DIRECTORY+"numbersSmall",
          XSTART+GAIN*5+24+j*16,i*GAIN+8+YSTART,numImages[j].to_i*16,0,16,16]
    end
    @voltorbNumbers[i]=[DIRECTORY+"numbersSmall",
        XSTART+GAIN*5+40,i*GAIN+34+YSTART,voltorbs*16,0,16,16]
    # Display the numbers
    pbDrawImagePositions(@sprites["numbers"].bitmap,@numbers)
    pbDrawImagePositions(@sprites["numbers"].bitmap,@voltorbNumbers)
  end

  def pbUpdateColumnNumbers(num,voltorbs,i)
    # Create and split a string for the number, with padded 0s
    zeroes=2-num.to_s.length
    numText=""
    for j in 0...zeroes
      numText+="0"
    end
    numText+=num.to_s
    numImages=numText.split(//)[0...2]
    for j in 0...2
      @numbers[j]=[DIRECTORY+"numbersSmall",
          (i*GAIN)+XSTART+24+j*16,8+YSTART+GAIN*5,numImages[j].to_i*16,0,16,16]
    end
    @voltorbNumbers[i]=[DIRECTORY+"numbersSmall",
        (i*GAIN)+XSTART+40,34+YSTART+GAIN*5,voltorbs*16,0,16,16]
    # Display the numbers
    pbDrawImagePositions(@sprites["numbers"].bitmap,@numbers)
    pbDrawImagePositions(@sprites["numbers"].bitmap,@voltorbNumbers)
  end

  def pbCreateCoins(source,x,y)
    ret=[]
    zeroes=5-source.to_s.length
    coinText=""
    for i in 0...zeroes
      coinText+="0"
    end
    coinText+=source.to_s
    coinImages=coinText.split(//)[0...5]
    for i in 0...5
      ret[i]=[DIRECTORY+"numbersScore",x+(i)*24,y,coinImages[i].to_i*24,0,24,38]
    end
    return ret
  end

  def pbUpdateCoins    
    # Update coins display
    @sprites["totalCoins"].bitmap.clear
    coins=pbCreateCoins(($game_party.gold/MULTIPLYMONEY)%100000,6,44)
    pbDrawImagePositions(@sprites["totalCoins"].bitmap,coins)
    # Update points display
    @sprites["currentCoins"].bitmap.clear
    coins=pbCreateCoins(@points,6,110)
    pbDrawImagePositions(@sprites["currentCoins"].bitmap,coins)
  end

  def pbAnimateTile(x,y,tile)
    icons=[]
    points=0
    for i in 0...3
      points=tile if i==2
      icons[i]=[DIRECTORY+"tiles",x,y,320+(i*64)+(points*64),0,64,64]
      pbDrawImagePositions(@sprites["icon"].bitmap,icons)
      wait(2)
    end
    icons[3]=[DIRECTORY+"tiles",x,y,tile*64,0,64,64]
    pbDrawImagePositions(@sprites["icon"].bitmap,icons)
    Audio.se_play("Audio/SE/Voltorb Flip Tile")
  end

  def pbShowAndDispose
    # Make pre-rendered sprites visible (this approach reduces lag)
    for i in 0...5
      @sprites[i].visible=true
      wait(1) if i<3
      @sprites[i].bitmap.clear
      @sprites[i].z=99997
    end
    Audio.se_play("Audio/SE/Voltorb Flip Tile")
    @sprites[5].visible=true
    @sprites["mark"].bitmap.clear
    wait(2)
    # Wait for user input to continue
    loop do
      wait(1)
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
    # "Dispose" of tiles by column
    for i in 0...5
      icons=[]
      Audio.se_play("Audio/SE/Voltorb Flip Tile")
      for j in 0...5
        icons[j]=[DIRECTORY+"tiles",@squares[i+(j*5)][0],@squares[i+(j*5)][1],448+(@squares[i+(j*5)][2]*64),0,64,64]
      end
      pbDrawImagePositions(@sprites[i].bitmap,icons)
      wait(2)
      for j in 0...5
        icons[j]=[DIRECTORY+"tiles",@squares[i+(j*5)][0],@squares[i+(j*5)][1],384,0,64,64]
      end
      pbDrawImagePositions(@sprites[i].bitmap,icons)
      wait(2)
      for j in 0...5
        icons[j]=[DIRECTORY+"tiles",@squares[i+(j*5)][0],@squares[i+(j*5)][1],320,0,64,64]
      end
      pbDrawImagePositions(@sprites[i].bitmap,icons)
      wait(2)
      for j in 0...5
        icons[j]=[DIRECTORY+"tiles",@squares[i+(j*5)][0],@squares[i+(j*5)][1],896,0,64,64]
      end
      pbDrawImagePositions(@sprites[i].bitmap,icons)
      wait(2)
    end
    @sprites["icon"].bitmap.clear
    for i in 0...6
      @sprites[i].bitmap.clear
    end
    @sprites["cursor"].bitmap.clear
  end
  
  def updateHighScores(points=nil)
    if points && @highScore.size>0 && @highScore[-1]<points
      if(@highScore.length==HIGH_SCORE_MAX_SIZE)
        @highScore.pop()
      end  
      @highScore.push(points)
      @highScore.sort!
      @highScore.reverse!
      $game_party.flipHighScore=@highScore
    end
    @sprites["highScoreCoins"].bitmap.clear
    for i in 0...@highScore.size
      coins=pbCreateCoins(@highScore[i],514,44+i*42)
      pbDrawImagePositions(@sprites["highScoreCoins"].bitmap,coins)
    end
  end  

  def wait(frames)
    frames.times do
      Graphics.update
      Input.update
    end
  end  

  def disposeSpriteHash(sprites)
    for id in sprites.keys
      sprite=sprites[id]
      if sprite && !sprite.disposed?
        sprite.dispose
      end
      sprites[id]=nil
    end
    sprites.clear
  end
  
  def pbDrawImagePositions(bitmap,textpos)
    for i in textpos
      srcbitmap=Sprite.new
      srcbitmap.bitmap=Bitmap.new(i[0])
      x=i[1]
      y=i[2]
      srcx=i[3]
      srcy=i[4]
      width=i[5]>=0 ? i[5] : srcbitmap.width
      height=i[6]>=0 ? i[6] : srcbitmap.height
      srcrect=Rect.new(srcx,srcy,width,height)
      bitmap.blt(x,y,srcbitmap.bitmap,srcrect)
      srcbitmap.dispose
    end
  end  
  
  def pbDrawShadowText(bitmap,x,y,width,height,string,baseColor,shadowColor=nil,align=0)
    return if !bitmap || !string
    width=(width<0) ? bitmap.text_size(string).width+4 : width
    height=(height<0) ? bitmap.text_size(string).height+4 : height
    if shadowColor
      bitmap.font.color=shadowColor
      bitmap.draw_text(x+2,y,width,height,string,align)
      bitmap.draw_text(x,y+2,width,height,string,align)
      bitmap.draw_text(x+2,y+2,width,height,string,align)
    end
    if baseColor
      bitmap.font.color=baseColor
      bitmap.draw_text(x,y,width,height,string,align)
    end
  end
      
  # Sprite class that maintains a bitmap of its own.
  # This bitmap can't be changed to a different one.
  class BitmapSprite < Sprite
    def initialize(width,height,viewport=nil)
      super(viewport)
      self.bitmap=Bitmap.new(width,height)
      @initialized=true
    end
  
    def bitmap=(value)
      super(value) if !@initialized
    end
  
    def dispose
      self.bitmap.dispose if !self.disposed?
      super
    end
  end

end

class Game_Party
  attr_accessor :flipHighScore
  def flipHighScore
    @flipHighScore||=[]
    return @flipHighScore
  end  
end  
  

module Graphics
  @@width=640
  @@height=480
  def self.width
    return @@width
  end
  def self.height
    return @@height
  end  
end