/*
 * audio_demo.c
 *
 *  Created on: May 8, 2013
 *      Author: jxciee
 */

#include <stdio.h>

#include "../../NIOS/software/Lab_6_bsp/system.h"
#include "../../NIOS/software/Lab_6_bsp/HAL/inc/alt_types.h"
#include "../../NIOS/software/Lab_6_bsp/HAL/inc/sys/alt_irq.h"
#include "../../NIOS/software/Lab_6_bsp/HAL/inc/priv/alt_legacy_irq.h"
#include "../../NIOS/software/Lab_6_bsp/HAL/inc/sys/alt_stdio.h"

//#include "altera_avalon_timer_regs.h"
//#include "altera_avalon_timer.h"


// create standard embedded type definitions
typedef   signed char   sint8;              // signed 8 bit values
typedef unsigned char   uint8;              // unsigned 8 bit values
typedef   signed short  sint16;             // signed 16 bit values
typedef unsigned short  uint16;             // unsigned 16 bit values
typedef   signed long   sint32;             // signed 32 bit values
typedef unsigned long   uint32;             // unsigned 32 bit values
typedef         float   real32;             // 32 bit real values

// Global variables
#define MAX_SAMPLES 				 (0x40000)//0x80000  //max sample data (16 bits each) for SDRAM

uint32 ECHO_CNT = 0;                      // index into buffer
uint32 SAMPLE_CNT = 0;                    //keep track of which sample is being read from SDRAM
uint32 CHANNELS = 1;
volatile uint16 TOGGLE = 0;

#define FIRST_TIME         1                // 1= means it is the first time running, so the file is loaded in SRAM

//set up pointers to peripherals
uint16* SdramPtr    = (uint16*)SDRAM_CONTROLLER_BASE;
uint32* AudioPtr    = (uint32*)AUDIO_MEMORY_BASE;
uint32* FilterPtr   = (uint32*)AUDIO_FILTER_0_BASE;
uint32* TimerPtr    = (uint32*)AUDIO_CLK_BASE;
uint32* SwPtr       = (uint32*)SWITCH_0_BASE;

//In this ISR, most of the processing is performed.  The timer interrupt is set for 20.83 us which is
// 1/48000.  By setting the timer interrupt at the sampling rate, a new sample is never missed and the
// audio output fifo never gets overloaded.  this is easier than using the interrupts provided with the
// audio core
void audio_out_isr(void *context)
{
	uint16 right_sample, left_sample;
	*TimerPtr = 0; //clear timer interrupt

	if (SAMPLE_CNT < MAX_SAMPLES)
	{
		left_sample = SdramPtr[SAMPLE_CNT++];  //read left side sample first
		
		// If switch is flipped, then put the sample through the filter
		// Write, then read should be filtered
		if(*SwPtr)
		{
			*FilterPtr = left_sample;
			left_sample = *FilterPtr;
		}

		if (CHANNELS == 2)                       //only read right sample if stereo mode
		{
			right_sample = SdramPtr[SAMPLE_CNT++];
			if(*SwPtr)
			{
				*FilterPtr = right_sample;
				right_sample = *FilterPtr;
			}

			AudioPtr[3] = right_sample;       //in stereo, output to both sides
			AudioPtr[2] = left_sample;
		}
		else
		{
			AudioPtr[3] = left_sample;       //in mono, output same sample to both sides
			AudioPtr[2] = left_sample;
		}
	}
	else      //this will allow continuous looping of audio.  comment this out to only play once
	{
		SAMPLE_CNT = 0;
	}


	return;
}



//this function reads a .wav file and stores the data in the SDRAM
//first it parses the header and stores that information in variables.
//Only files with 48K sample rates and 16 bit data will work with this program.

void read_file(void)
{
	//buffers for the header information
	uint8 ChunkID[4], Format[4], Subchunk1ID[4], Subchunk2ID[4];
	uint32 ChunkSize,Subchunk1Size, SampleRate, ByteRate, Subchunk2Size;
	uint16 AudioFormat, NumChannels, BlockAlign, BitsPerSample;
	uint16 Data;
	FILE* fp;
	uint32 i = 0;

	//start reading
	printf("Opening file...\n");
	fp = fopen("/mnt/host/piano2.wav", "r");

	if(fp == NULL)
	{
		printf("error, no file open!\n");
	}

	else
	{
		printf("file opened.\n");
		fread(ChunkID,1,4,fp);
		fread(&ChunkSize,4,1,fp);
		fread(Format,1,4,fp);
		fread(Subchunk1ID,1,4,fp);
		fread(&Subchunk1Size,4,1,fp);
		fread(&AudioFormat,2,1,fp);
		fread(&NumChannels,2,1,fp);
		fread(&SampleRate,4,1,fp);
		fread(&ByteRate,4,1,fp);
		fread(&BlockAlign,2,1,fp);
		fread(&BitsPerSample,2,1,fp);
		fread(&Subchunk2ID,1,4,fp);
		fread(&Subchunk2Size,4,1,fp);

		CHANNELS = NumChannels;

		while (i < MAX_SAMPLES)
		{
			if((i % 1000) == 0)
				printf("Reading... %u/%u\n", i, MAX_SAMPLES);

			fread(&Data, 2, 1, fp); //read the file in one short int at a time
			SdramPtr[i++] = Data;   //store in sdram.
		}

		printf("file read \n");     //let user know file was read
	}
}


// BSP Settings:
// 		NOTE: Drivers -> Setting/Advanced/altera_avalon_jtag_uart_driver/enable_small_driver is set to true to enable print to Nios II Console
//		NOTE: Software Packages -> altera_hostfs is enabled to allow opening files through jtag

// NOTE: For some reason the Eclipse project settings are screwed up and generates the bsp into root nios project dir instead of /software/lab_6_bsp. Just copy it over

// NOTE: File I/O only works when debugging and not running

int main(void)
{
	printf("ESD-I Audio Demo Program Running.\n");

//#if (FIRST_TIME)
//	read_file();
//#endif

	//initialize timer interrupt 48Khz
	alt_irq_register(AUDIO_CLK_IRQ, 0, audio_out_isr);

	while (1);
	return 0;
}
