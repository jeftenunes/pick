**cgroups**
    Isolamento de recursos computacionais (CPU, IO, memoria)

**namespaces**
    Isolamento de usuarios, network, filesystem, processos

**Copy-On-Write**
    Quando um processo tenta alterar o conteudo de uma area de memoria, o SO cria uma copia do conteudo para o processo que o altera
    A copia somente eh criada qndo ha escrita