#ifndef Fat16util_h
#define Fat16util_h
/* Arduino FAT16 Library
 * Copyright (C) 2008 by William Greiman
 *  
 * This file is part of the Arduino FAT16 Library
 *  
 * This Library is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by 
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This Library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Arduino Fat16 Library.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
/**
 * \file
 * Useful utility functions.
 */     
#include <WProgram.h>
#include <avr/pgmspace.h>
/** Store and print a string in flash memory.*/
#define PgmPrint(x) SerialPrint_P(PSTR(x))
/** Store and print a string in flash memory followed by a CR/LF.*/
#define PgmPrintln(x) SerialPrintln_P(PSTR(x))
/** Defined so doxygen works for function definitions. */
#define NOINLINE __attribute__((noinline)) 
//------------------------------------------------------------------------------
/** Return the number of bytes currently free in RAM. */
static int FreeRam(void)
{
  extern int  __bss_end;
  extern int  *__brkval;
  int free_memory;
  if((int)__brkval == 0) {
    // if no heap use from end of bss section
    free_memory = ((int)&free_memory) - ((int)&__bss_end);
  }
  else {
    // use from top of stack to heap
    free_memory = ((int)&free_memory) - ((int)__brkval);
  }
  return free_memory;
}
//------------------------------------------------------------------------------
/** 
 * %Print a string in flash memory to the serial port. 
 * 
 * \param[in] str Pointer to string stored in flash memory.  
 */
static NOINLINE void SerialPrint_P(PGM_P str) 
{
  for (uint8_t c; (c = pgm_read_byte(str)); str++) Serial.print(c);
}
//------------------------------------------------------------------------------
/** 
 * %Print a string in flash memory followed by a CR/LF. 
 * 
 * \param[in] str Pointer to string stored in flash memory. 
 */
static NOINLINE void SerialPrintln_P(PGM_P str)
{
  SerialPrint_P(str);
  Serial.println();
}
#endif // #define Fat16util_h