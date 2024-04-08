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

task clair3 {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-10-18"
	}

	input {
		String path_exe = "run_clair3.sh"
		String outputPath

		String modelPath
		String model = "ont"

		File refGenome
		File refGenomeIndex

		File bamFile
		File bamFileIndex

		File? bedFile

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

		~{path_exe} callVarBam \
			--model_path=~{modelPath} \
			--platform=~{model} \
			--ref_fn=~{refGenome} \
			~{default="" "--bed_fn=" + bedFile} \
			--bam_fn=~{bamFile} \
			--output=~{outputPath} \
			--remove_intermediate_dir \
			--threads=~{threads}

	>>>

	output {
		File outputFile = "~{outputPath}/merge_output.vcf.gz"
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	# generate documentation
	parameter_meta {
		path_exe: {
			description: 'Path to CLAIR python script [default: "clair.py"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where vcf file was generated. [default: pwd()]',
			category: 'Output'
		}
		modelPath: {
			description: 'Path to the model folder',
			category: 'input'
		}
		model: {
			description: 'Model',
			category: 'input'
		}
		refGenome: {
			description: 'Reference fasta file input, [default: ref.fa]',
			category: 'input'
		}
		refGenomeIndex: {
			description: 'Index of the FASTA reference.',
			category: 'input'
		}
		bedFile: {
			description: 'Call variant only in these regions',
			category: 'Option'
		}
		bamFile: {
			description: 'BAM file input',
			category: 'input'
		}
		bamFileIndex: {
			description: 'Index of the bam file',
			category: 'input'
		}
		threads: {
			description: 'Number of threads, optional',
			category: 'System'
		}
		memoryByThreads: {
			description: '',
			category: 'System'
		}
		memory: {
			description: '',
			category: 'System'
		}
	}
}
