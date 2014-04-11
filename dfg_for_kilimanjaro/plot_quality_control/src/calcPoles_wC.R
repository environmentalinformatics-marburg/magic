### function for conversion of degrees to radians
radians <- function(degrees) degrees * pi / 180

### function to calculate xy offset
dirdis2xy <- function(dir, dis) {
  
  radians <- function(degrees) degrees * pi / 180
  u <- -dis * sin(radians(dir))
  x <- round(-u, 2)
  
  v <- -dis * cos(radians(dir))
  y <- round(-v, 2)
  
  return(as.data.frame(cbind(x, y)))
  
}

### function to calculate position of poles
calcPoles <- function(a.x, a.y, orientation = 0, size.x, size.y,
                      whitaker.x = 50, whitaker.y = 20, C = FALSE) {
  
  size.x <- ifelse(size.x == 100, size.x / 2, size.x)
  size.y <- ifelse(size.y == 100, size.y / 2, size.y)
  
  b2offset <- dirdis2xy(orientation, size.y/2)
  b2 <- data.frame(x = as.integer(b2offset$x + a.x), 
                   y = as.integer(b2offset$y + a.y))

  c3offset <- dirdis2xy(orientation, size.y)
  c3 <- data.frame(x = as.integer(c3offset$x + a.x), 
                   y = as.integer(c3offset$y + a.y))
  
  b7offset <- dirdis2xy(orientation + 180, size.y/2)
  b7 <- data.frame(x = as.integer(b7offset$x + a.x), 
                   y = as.integer(b7offset$y + a.y))
  
  c14offset <- dirdis2xy(orientation + 180, size.y)
  c14 <- data.frame(x = as.integer(c14offset$x + a.x), 
                    y = as.integer(c14offset$y + a.y))
  
  b1offset <- dirdis2xy(270 + orientation, size.x/2)
  b1 <- data.frame(x = as.integer(b1offset$x + b2$x), 
                   y = as.integer(b1offset$y + b2$y))
  
  c1offset <- dirdis2xy(270 + orientation, size.x)
  c1 <- data.frame(x = as.integer(c1offset$x + c3$x), 
                   y = as.integer(c1offset$y + c3$y))
  
  c2offset <- dirdis2xy(270 + orientation, size.x/2)
  c2 <- data.frame(x = as.integer(c2offset$x + c3$x), 
                   y = as.integer(c2offset$y + c3$y))
  
  c6offset <- dirdis2xy(270 + orientation, size.x)
  c6 <- data.frame(x = as.integer(c6offset$x + b2$x), 
                   y = as.integer(c6offset$y + b2$y))
  
  b3offset <- dirdis2xy(90 + orientation, size.x/2)
  b3 <- data.frame(x = as.integer(b3offset$x + b2$x), 
                   y = as.integer(b3offset$y + b2$y))
  
  c5offset <- dirdis2xy(90 + orientation, size.x)
  c5 <- data.frame(x = as.integer(c5offset$x + c3$x), 
                   y = as.integer(c5offset$y + c3$y))
  
  c4offset <- dirdis2xy(90 + orientation, size.x/2)
  c4 <- data.frame(x = as.integer(c4offset$x + c3$x), 
                   y = as.integer(c4offset$y + c3$y))
  
  c7offset <- dirdis2xy(90 + orientation, size.x)
  c7 <- data.frame(x = as.integer(c7offset$x + b2$x), 
                   y = as.integer(c7offset$y + b2$y))
  
  b6offset <- dirdis2xy(270 + orientation, size.x/2)
  b6 <- data.frame(x = as.integer(b6offset$x + b7$x), 
                   y = as.integer(b6offset$y + b7$y))
  
  c12offset <- dirdis2xy(270 + orientation, size.x)
  c12 <- data.frame(x = as.integer(c12offset$x + c14$x), 
                    y = as.integer(c12offset$y + c14$y))
  
  c10offset <- dirdis2xy(270 + orientation, size.x)
  c10 <- data.frame(x = as.integer(c10offset$x + b7$x), 
                    y = as.integer(c10offset$y + b7$y))
  
  c13offset <- dirdis2xy(270 + orientation, size.x/2)
  c13 <- data.frame(x = as.integer(c13offset$x + c14$x), 
                    y = as.integer(c13offset$y + c14$y))
  
  b8offset <- dirdis2xy(90 + orientation, size.x/2)
  b8 <- data.frame(x = as.integer(b8offset$x + b7$x), 
                   y = as.integer(b8offset$y + b7$y))
  
  c16offset <- dirdis2xy(90 + orientation, size.x)
  c16 <- data.frame(x = as.integer(c16offset$x + c14$x), 
                    y = as.integer(c16offset$y + c14$y))
  
  c11offset <- dirdis2xy(90 + orientation, size.x)
  c11 <- data.frame(x = as.integer(c11offset$x + b7$x), 
                    y = as.integer(c11offset$y + b7$y))
  
  c15offset <- dirdis2xy(90 + orientation, size.x/2)
  c15 <- data.frame(x = as.integer(c15offset$x + c14$x), 
                    y = as.integer(c15offset$y + c14$y))
  
  b4offset <- dirdis2xy(270 + orientation, size.x/2)
  b4 <- data.frame(x = as.integer(b4offset$x + a.x), 
                   y = as.integer(b4offset$y + a.y))
  
  c8offset <- dirdis2xy(270 + orientation, size.x)
  c8 <- data.frame(x = as.integer(c8offset$x + a.x), 
                   y = as.integer(c8offset$y + a.y))
  
  b5offset <- dirdis2xy(90 + orientation, size.x/2)
  b5 <- data.frame(x = as.integer(b5offset$x + a.x), 
                   y = as.integer(b5offset$y + a.y))
  
  c9offset <- dirdis2xy(90 + orientation, size.x)
  c9 <- data.frame(x = as.integer(c9offset$x + a.x), 
                   y = as.integer(c9offset$y + a.y))
  
  #I think this only works if the plots would be noth south so i changed it
  #c2 <- data.frame(x = c3$x - size.x / 2,
   #                y = c3$y)
  
  #c4 <- data.frame(x = c3$x + size.x / 2,
   #                y = c3$y)
  
  #c6 <- data.frame(x = c8$x,
  #                y = c8$y + size.y / 2)
  
  #c10 <- data.frame(x = c8$x,
   #                 y = c8$y - size.y / 2)
  
  #c7 <- data.frame(x = c9$x,
  #                 y = c9$y + size.y / 2)
  
  #c11 <- data.frame(x = c9$x,
  #                  y = c9$y - size.y / 2)
  
  #c13 <- data.frame(x = c14$x - size.x / 2,
  #                  y = c14$y)
  
  #c15 <- data.frame(x = c14$x + size.x / 2,
  #                  y = c14$y)
  
  tm1offset <- dirdis2xy(orientation, whitaker.y/2)
  tm1 <- data.frame(x = as.integer(tm1offset$x + a.x), 
                    y = as.integer(tm1offset$y + a.y))
  
  tm2offset <- dirdis2xy(orientation + 180, whitaker.y/2)
  tm2 <- data.frame(x = as.integer(tm2offset$x + a.x), 
                    y = as.integer(tm2offset$y + a.y))
  
  t1offset <- dirdis2xy(270 + orientation, whitaker.x/2)
  t1 <- data.frame(x = as.integer(t1offset$x + tm1$x), 
                   y = as.integer(t1offset$y + tm1$y))
  
  t2offset <- dirdis2xy(90 + orientation, whitaker.x/2)
  t2 <- data.frame(x = as.integer(t2offset$x + tm1$x), 
                   y = as.integer(t2offset$y + tm1$y))
  
  t3offset <- dirdis2xy(270 + orientation, whitaker.x/2)
  t3 <- data.frame(x = as.integer(t3offset$x + tm2$x), 
                   y = as.integer(t3offset$y + tm2$y))
  
  t4offset <- dirdis2xy(90 + orientation, whitaker.x/2)
  t4 <- data.frame(x = as.integer(t4offset$x + tm2$x), 
                   y = as.integer(t4offset$y + tm2$y))
  
  am1offset <- dirdis2xy(orientation, 5/2)
  am1 <- data.frame(x = as.integer(am1offset$x + a.x), 
                    y = as.integer(am1offset$y + a.y))
  
  am2offset <- dirdis2xy(orientation + 180, 5/2)
  am2 <- data.frame(x = as.integer(am2offset$x + a.x), 
                    y = as.integer(am2offset$y + a.y))
  
  a1offset <- dirdis2xy(270 + orientation, 20/2)
  a1 <- data.frame(x = as.integer(a1offset$x + am1$x), 
                   y = as.integer(a1offset$y + am1$y))
  
  a2offset <- dirdis2xy(90 + orientation, 20/2)
  a2 <- data.frame(x = as.integer(a2offset$x + am1$x), 
                   y = as.integer(a2offset$y + am1$y))
  
  a3offset <- dirdis2xy(270 + orientation, 20/2)
  a3 <- data.frame(x = as.integer(a3offset$x + am2$x), 
                   y = as.integer(a3offset$y + am2$y))
  
  a4offset <- dirdis2xy(90 + orientation, 20/2)
  a4 <- data.frame(x = as.integer(a4offset$x + am2$x), 
                   y = as.integer(a4offset$y + am2$y))
  
  b10offset <- dirdis2xy(orientation, size.y/2+30)
  b10 <- data.frame(x = as.integer(b10offset$x + a.x), 
                   y = as.integer(b10offset$y + a.y))
  
  b13offset <- dirdis2xy(orientation, size.y/2+10)
  b13 <- data.frame(x = as.integer(b13offset$x + a.x), 
                   y = as.integer(b13offset$y + a.y))
  
  b11offset <- dirdis2xy(90+orientation, size.y/2+30)
  b11 <- data.frame(x = as.integer(b11offset$x + a.x), 
                   y = as.integer(b11offset$y + a.y))
    
  polesAB <- list(A = data.frame(x = a.x, y = a.y), 
                  B1 = b1, 
                  B2 = b2, 
                  B3 = b3, 
                  B4 = b4, 
                  B5 = b5, 
                  B6 = b6, 
                  B7 = b7, 
                  B8 = b8, 
                  B10 = b10, 
                  B11 = b11, 
                  B13 = b13,
                  TM1 = tm1,
                  TM2 = tm2,
                  T1 = t1,
                  T2 = t2,
                  T3 = t3,
                  T4 = t4,
                  A1 = a1,
                  A2 = a2,
                  A3 = a3,
                  A4 = a4
  )
  
  polesC <- list(C1 = c1, 
                 C2 = c2, 
                 C3 = c3, 
                 C4 = c4, 
                 C5 = c5, 
                 C6 = c6, 
                 C7 = c7, 
                 C8 = c8,
                 C9 = c9,
                 C10 = c10, 
                 C11 = c11, 
                 C12 = c12,
                 C13 = c13,
                 C14 = c14,
                 C15 = c15,
                 C16 = c16
  )
  
  out <- if (isTRUE(C)) {
    out <- c(polesAB, polesC)
    } else {
      out <- polesAB
    }
  
  return(out)
}
