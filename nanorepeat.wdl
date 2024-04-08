version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2021 MoBiDiC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

task nanorepeat {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-10-18"
	}

	input {
		String path_exe = "nanoRepeat.py"

		File bamFile
		File bamFileIndex

		File refGenome
		File refGenomeIndex
		File? bedFile
		String outputPath
		String dataType = "ont"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<

		if [[ ! -d $(dirname ~{outputPath}) ]]; then
			mkdir -p $(dirname ~{outputPath})
		fi

		~{path_exe} \
			--input ~{bamFile} \
			--type bam \
			--ref_fasta ~{refGenome} \
			--repeat_region_bed ~{bedFile} \
			--out_prefix ~{outputPath} \
			--data_type ~{dataType} \
			--num_cpu ~{threads}
		
	>>>

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "nanoRepeat.py"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where files were generated.',
			category: 'Output'
		}
		bamFile: {
			description: 'BAM input file.',
			category: 'Required'
		}
		bamFileIndex: {
			description: 'BAM index',
			category: 'Required'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}