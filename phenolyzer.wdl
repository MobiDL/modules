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


task phenolyzer {
	meta {
		author: "Olivier Ardouin"
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-10-26"
	}
	input {
		String name
    String outputPath = "/."
		String DiseaseFile

		String PerlExe = "perl"
		String PhenolyzerPath = "/phenolyzer"

		## run time
    Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String outputFile = if defined(outputPath) then outputPath + "/" + name else name

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		if [[ ! -f "~{DiseaseFile}" ]]; then
			if [[ ! -d $(dirname ~{DiseaseFile}) ]]; then
				mkdir -p $(dirname ~{DiseaseFile})
			fi
			touch ~{DiseaseFile}
		fi
			~{PerlExe} ~{PhenolyzerPath}/disease_annotation.pl ~{DiseaseFile} -f -p -ph -logistic -out ~{outputFile}
	>>>

	output {
		String? outPhenolyzer = "~{outputFile}.predicted_gene_scores"
	}

	runtime {
    cpu: "~{threads}"
    requested_memory_mb_per_core: "${memoryByThreadsMb}"
  }
}
