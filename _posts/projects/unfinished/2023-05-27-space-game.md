---
layout: post
title: space-game
subtitle: An old project
gh-repo: youngspe/space-game
# gh-badge: [star, fork, follow]
# tags: [test]
# comments: true
# cover-img: /assets/img/path.jpg
# thumbnail-img: /assets/img/thumb.png
# share-img: /assets/img/path.jpg
date: 2023-05-27 23:00:00
---

Check it out here: [youngspe.github.io/space-game](https://youngspe.github.io/space-game) ([source](https://github.com/youngspe/space-game))

Several years ago I made a simple game as I experimented with TypeScript as well as HTML canvas. The player controls a hexagon-shaped spaceship while being chased by circular spaceships. The goal is to shoot down the circles as they spawn and survive as long as you can.

The controls are completely unintuitive. The QWEASD keys move the spaceship around; instead of WASD where each key corresponds to the four cardinal directions, the QWEASD keys correspond to six evenly-spaced directions, reflecting the vertices of the hexagonal ship.
Shooting is much more straightfoward; simply click on a point on the screen you'd like to shoot.

I made my own little entity-component-system engine and rolled my own physics with circle-circle collisions. It's definitely unfinished, so there's nothing stopping you from disappearing off the side of the screen, and when you die the game just slows to a stop.
