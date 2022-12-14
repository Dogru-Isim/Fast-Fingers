import std/[terminal, os, strutils, random, sequtils, parseopt]
import system

let width = terminalWidth()

proc removeUnfinishedSentence(text: var string) =
  while true:
    if len(text) == 0:
      echo "Please provide a longer length ex:(./main 300)"
      quit(0)
    elif text[^1] != '.':
      text = text[0..^2]
    else:                       #TODO: This is not the best solution since there will be dots at the middle of a sentence ("1." i.e)
      break

proc getTextLength(): int =
  var length = initOptParser()
  while true:
    length.next()
    case length.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption: discard
    of cmdArgument:
      return parseInt(length.key)
  
#[
  TODO: Get texts from sources on the internet based on their length (preferably the Britannica API)

  DONE:
  If the user doesn't have an internet connection, use those text files
  If the last sentence is not finished, don't include it.
]#
proc getText(numOfCharacters: int = getTextLength()): string =
  var realNumOfCharacters: BiggestInt = numOfCharacters
  let textDir = toSeq(walkDir("texts"))
  let sizeOfDir = len(textDir)  # Get the amount of texts that can be used
  let file: int = rand(1..sizeOfDir) # Choose a random file among them

  result = readFile(textDir[file-1].path)

  if numOfCharacters > getFileSize(textDir[file-1].path):  # If provided length is longer than file size, make them equal
    realNumOfCharacters = getFileSize(textDir[file-1].path)

  while true:
    if len(result) == realNumOfCharacters: break
    else:
      result = result[0..^2]

  removeUnfinishedSentence(result)


let text = getText()  # Choose a text
proc prepare() =
  eraseScreen()
  setCursorPos(0, 0)
  stdout.write(text)
  setCursorPos(0, 0)

# There is no built-in getCursorPos, 
# Thanks to: cagyul in https://forum.nim-lang.org/t/9475, I modified it a bit for my needs.
proc getCursorPos(charsToWrite: string): tuple[x,y: int] =
   stdout.write "\e[6n"       # get cursor coordinates
   discard getch()              # ignore \e
   discard getch()              # ignore [
   var c = getch()
   stdout.write "\e[y;xR"     # read y,x values of cursor position
   while c != ';':
      result.y = result.y * 10 + (int(c) - int('0'))
      c = getch()
   c = getch()
   while c != 'R':
      result.x = result.x * 10 + (int(c) - int('0'))
      c = getch()
   result.x -= 1
   result.y -= 1
   setCursorPos(result.x, result.y)      # place cursor at proper position
   stdout.write charsToWrite                     # overwrite side-effect text ";xR"
   setCursorPos(result.x, result.y)      # return cursor to proper position


# Get users input char by char, compare it with the text
proc main(): void =
  let text = getText()  # Choose a text

  var i = 0
  while i < len(text):
    try:
      var input = getch()
   
      if toHex($input) == "1B":    # ESCAPE
        eraseScreen()
        quit(0)
      elif toHex($input) == "03":  # CTRL+C
        eraseScreen()
        quit(130)
      elif $input == $text[i]:     # If input is correct
        stdout.write($input)
        inc i
      elif toHex($input) == "7F":  # If input is backspace
        var chars = $text[i] & $text[i+1] & $text[i+2] & $text[i+3]  # To overwrite getCursorPos's side-effect: ";xR"
        var cursorPos = getCursorPos(chars)
        if cursorPos[0] == 0:
          if cursorPos[1] == 0:  # If cursor is at the top, don't do anything
            continue
          else:
            dec i
            var yPosToSet = cursorPos[1] - 1
            setCursorPos(width, yPosToSet)
        else:
          dec i
          stdout.cursorBackward()
          stdout.write($text[i])
          stdout.cursorBackward()
      elif $input != $text[i]:      # If input is incorrect
        stdout.styledWrite(fgRed, $text[i])
        inc i
    except:
      quit("Unexpected error", 1)


when isMainModule:
  prepare()
  main()
