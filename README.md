# Cookie Monster

<img align="left" width="96" height="96" src="/Cookie%20Monster/Assets.xcassets/AppIcon.appiconset/cookie_monster.png">
Cookie Monster is a modern implementation of the classic game Jawbreaker for iOS.
The game board consists of a screen of different kinds of cookies arranged in a matrix.
The player then clicks on any two or more connecting same-kind cookies to eliminate them
from the matrix, earning an appropriate number of points in the process. The more cookies
eliminated at once, the higher the points added to the player's score.

<p align="center">
<img src="Screenshots/iPhone 12 Pro Max.png" 
        alt="Cookie Monster" 
        width="200"
        style="display: block; margin: 20 auto;" />
</p>

The scoring can be expressed in the formula "Y=X(X-1)". X represents the number of cookies
grouped together, Y is the resulting score. For example an elimination of 16 cookies will
result in 240 points (240=16(16-1)).

The game ends when the player has no more moves left, i.e. there are no more same-kind cookies
adjacent to each other.
